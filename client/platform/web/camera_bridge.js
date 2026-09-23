// Web camera and motion bridge for WebPlatform (client/platform/web/web_platform.gd). Loaded into the
// page with JavaScriptBridge.eval. Frames are processed here and only results go to Godot: a small
// RGB preview, QR text, face boxes, step count. Raw camera frames never leave the browser.
//
// Libraries come from cdn.jsdelivr.net on first use (the phone needs internet): jsQR for QR codes,
// MediaPipe Tasks Vision (face landmarker with blendshapes) for faces and smiles.
window.alfaCamera = window.alfaCamera || (function () {
	'use strict';

	var JSQR_URL = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js';
	var VISION_URL = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@1.0.1/vision_bundle.mjs';
	var VISION_WASM = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@1.0.1/wasm';
	var FACE_MODEL = 'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task';
	var PREVIEW_LONG_SIDE = 160;
	var QR_LONG_SIDE = 480;
	var FRAME_INTERVAL_MS = 66;
	var QR_INTERVAL_MS = 150;
	var FACES_INTERVAL_MS = 100;
	var QR_REPEAT_MS = 1500;
	var MAX_FACES = 4;

	var state = {
		stream: null, video: null, mode: 'preview', front: false, timer: 0, callbacks: null,
		lastQrAt: 0, lastFacesAt: 0, lastQrText: '', lastQrTextAt: 0,
		preview: document.createElement('canvas'), scan: document.createElement('canvas'),
		jsQR: null, landmarker: null, loading: {}, cameraPermission: 'unknown',
	};

	function loadScript(url) {
		return new Promise(function (resolve, reject) {
			var script = document.createElement('script');
			script.src = url;
			script.onload = resolve;
			script.onerror = function () { reject(new Error('load ' + url)); };
			document.head.appendChild(script);
		});
	}

	function ensureQr() {
		if (state.jsQR) { return Promise.resolve(); }
		if (!state.loading.qr) {
			state.loading.qr = loadScript(JSQR_URL).then(function () { state.jsQR = window.jsQR; });
		}
		return state.loading.qr;
	}

	function ensureFaces() {
		if (state.landmarker) { return Promise.resolve(); }
		if (!state.loading.faces) {
			state.loading.faces = import(VISION_URL).then(function (vision) {
				return vision.FilesetResolver.forVisionTasks(VISION_WASM).then(function (fileset) {
					return vision.FaceLandmarker.createFromOptions(fileset, {
						baseOptions: { modelAssetPath: FACE_MODEL, delegate: 'GPU' },
						runningMode: 'VIDEO', numFaces: MAX_FACES, outputFaceBlendshapes: true,
					});
				});
			}).then(function (landmarker) { state.landmarker = landmarker; });
		}
		return state.loading.faces;
	}

	function report(name) {
		var args = Array.prototype.slice.call(arguments, 1);
		if (state.callbacks && state.callbacks[name]) {
			state.callbacks[name].apply(null, args);
		}
	}

	function openStream(front) {
		return navigator.mediaDevices.getUserMedia({
			audio: false,
			video: { facingMode: front ? 'user' : 'environment', width: { ideal: 640 }, height: { ideal: 480 } },
		});
	}

	// Draws the current video frame into `canvas` scaled to `longSide`, mirrored for the front camera.
	function grab(canvas, longSide, mirror) {
		var video = state.video;
		var scale = longSide / Math.max(video.videoWidth, video.videoHeight);
		var width = Math.max(1, Math.round(video.videoWidth * scale));
		var height = Math.max(1, Math.round(video.videoHeight * scale));
		if (canvas.width !== width || canvas.height !== height) {
			canvas.width = width;
			canvas.height = height;
		}
		var context = canvas.getContext('2d', { willReadFrequently: true });
		context.save();
		if (mirror) {
			context.translate(width, 0);
			context.scale(-1, 1);
		}
		context.drawImage(video, 0, 0, width, height);
		context.restore();
		return context.getImageData(0, 0, width, height);
	}

	function sendPreview() {
		var image = grab(state.preview, PREVIEW_LONG_SIDE, state.front);
		var rgba = image.data;
		var rgb = new Uint8Array(image.width * image.height * 3);
		for (var i = 0, j = 0; i < rgba.length; i += 4, j += 3) {
			rgb[j] = rgba[i];
			rgb[j + 1] = rgba[i + 1];
			rgb[j + 2] = rgba[i + 2];
		}
		report('frame', image.width, image.height, rgb.buffer);
	}

	function scanQr(now) {
		if (!state.jsQR || now - state.lastQrAt < QR_INTERVAL_MS) { return; }
		state.lastQrAt = now;
		var image = grab(state.scan, QR_LONG_SIDE, false);
		var code = state.jsQR(image.data, image.width, image.height, { inversionAttempts: 'attemptBoth' });
		if (!code || !code.data) { return; }
		if (code.data === state.lastQrText && now - state.lastQrTextAt < QR_REPEAT_MS) { return; }
		state.lastQrText = code.data;
		state.lastQrTextAt = now;
		report('qr', code.data);
	}

	function smile(blendshapes) {
		if (!blendshapes || !blendshapes.categories) { return -1; }
		var total = 0;
		var found = 0;
		blendshapes.categories.forEach(function (category) {
			if (category.categoryName === 'mouthSmileLeft' || category.categoryName === 'mouthSmileRight') {
				total += category.score;
				found += 1;
			}
		});
		return found > 0 ? Math.min(1, total / found * 1.6) : -1;
	}

	function detectFaces(now) {
		if (!state.landmarker || now - state.lastFacesAt < FACES_INTERVAL_MS) { return; }
		state.lastFacesAt = now;
		var result = state.landmarker.detectForVideo(state.video, now);
		var faces = (result.faceLandmarks || []).map(function (points, index) {
			var minX = 1, minY = 1, maxX = 0, maxY = 0;
			points.forEach(function (point) {
				minX = Math.min(minX, point.x); maxX = Math.max(maxX, point.x);
				minY = Math.min(minY, point.y); maxY = Math.max(maxY, point.y);
			});
			var x = state.front ? 1 - maxX : minX;
			return { x: x, y: minY, w: maxX - minX, h: maxY - minY, smiling: smile((result.faceBlendshapes || [])[index]) };
		});
		report('faces', JSON.stringify({ faces: faces }));
	}

	function tick() {
		if (!state.video || state.video.readyState < 2) { return; }
		var now = performance.now();
		sendPreview();
		if (state.mode === 'qr') { scanQr(now); }
		if (state.mode === 'faces') { detectFaces(now); }
	}

	function stop() {
		clearInterval(state.timer);
		state.timer = 0;
		if (state.stream) {
			state.stream.getTracks().forEach(function (track) { track.stop(); });
		}
		state.stream = null;
		if (state.video) {
			state.video.srcObject = null;
			state.video.remove();
		}
		state.video = null;
	}

	// callbacks: {frame(width, height, rgbBuffer), qr(text), faces(json), error(code)}.
	function start(mode, front, callbacks) {
		stop();
		state.mode = mode;
		state.front = !!front;
		state.callbacks = callbacks;
		state.lastQrText = '';
		var ready = mode === 'qr' ? ensureQr() : mode === 'faces' ? ensureFaces() : Promise.resolve();
		ready.catch(function () { report('error', 'library'); });
		openStream(state.front).then(function (stream) {
			state.cameraPermission = 'granted';
			state.stream = stream;
			var video = document.createElement('video');
			// iOS plays inline video only when muted and playsinline.
			video.setAttribute('playsinline', '');
			video.muted = true;
			video.style.cssText = 'position:fixed;width:1px;height:1px;opacity:0;pointer-events:none;';
			document.body.appendChild(video);
			video.srcObject = stream;
			state.video = video;
			return video.play();
		}).then(function () {
			state.timer = setInterval(tick, FRAME_INTERVAL_MS);
		}).catch(function (error) {
			state.cameraPermission = error && error.name === 'NotAllowedError' ? 'denied' : state.cameraPermission;
			report('error', error && error.name === 'NotAllowedError' ? 'denied' : 'unavailable');
			stop();
		});
	}

	// Asks for the camera once so the permission prompt appears before a minigame starts.
	function requestPermission() {
		if (state.cameraPermission !== 'unknown' && state.cameraPermission !== 'pending') { return; }
		if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
			state.cameraPermission = 'unsupported';
			return;
		}
		state.cameraPermission = 'pending';
		openStream(false).then(function (stream) {
			stream.getTracks().forEach(function (track) { track.stop(); });
			state.cameraPermission = 'granted';
		}).catch(function (error) {
			state.cameraPermission = error && error.name === 'NotAllowedError' ? 'denied' : 'unsupported';
		});
	}

	function supported() {
		return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia) && window.isSecureContext;
	}

	return {
		start: start,
		stop: stop,
		supported: supported,
		requestPermission: requestPermission,
		permission: function () { return state.cameraPermission; },
		preload: function (mode) { return mode === 'qr' ? ensureQr() : mode === 'faces' ? ensureFaces() : null; },
	};
})();

// Motion: iOS 13+ lets a page read DeviceMotionEvent only after DeviceMotionEvent.requestPermission(),
// and only from a user gesture. Godot handles input outside the DOM event, so the bridge asks on the
// first tap on the page. Steps are counted here from the acceleration magnitude.
window.alfaMotion = window.alfaMotion || (function () {
	'use strict';

	var STEP_THRESHOLD = 1.2;
	var STEP_MIN_INTERVAL_MS = 300;
	var SMOOTHING = 0.2;

	var state = { permission: 'unknown', steps: 0, counting: false, filtered: 0, above: false, lastStepAt: 0 };

	function needsPermission() {
		return typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function';
	}

	function askOnGesture() {
		if (!needsPermission()) {
			state.permission = typeof DeviceMotionEvent !== 'undefined' ? 'granted' : 'unsupported';
			return;
		}
		var ask = function () {
			document.removeEventListener('touchend', ask, true);
			document.removeEventListener('click', ask, true);
			DeviceMotionEvent.requestPermission().then(function (result) {
				state.permission = result === 'granted' ? 'granted' : 'denied';
			}).catch(function () { state.permission = 'denied'; });
		};
		document.addEventListener('touchend', ask, true);
		document.addEventListener('click', ask, true);
	}

	// Peak detection on the low-pass filtered magnitude of the acceleration without gravity.
	function onMotion(event) {
		if (!state.counting) { return; }
		var a = event.acceleration;
		if (!a || a.x === null) {
			a = event.accelerationIncludingGravity;
			if (!a || a.x === null) { return; }
		}
		var magnitude = Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
		if (event.acceleration === null || event.acceleration.x === null) {
			magnitude = Math.abs(magnitude - 9.81);
		}
		state.filtered += SMOOTHING * (magnitude - state.filtered);
		var now = performance.now();
		if (!state.above && state.filtered > STEP_THRESHOLD && now - state.lastStepAt > STEP_MIN_INTERVAL_MS) {
			state.above = true;
			state.lastStepAt = now;
			state.steps += 1;
		} else if (state.above && state.filtered < STEP_THRESHOLD * 0.5) {
			state.above = false;
		}
	}

	window.addEventListener('devicemotion', onMotion);
	askOnGesture();

	return {
		permission: function () { return state.permission; },
		startSteps: function () { state.steps = 0; state.filtered = 0; state.above = false; state.counting = true; },
		stopSteps: function () { state.counting = false; },
		steps: function () { return state.steps; },
	};
})();
