class_name Palette
extends RefCounted
## Colour ramps with hue shifting: shadows lean cool/purple, highlights lean warm.

const ALFA_RED: Color = Color("#ef3124")
const INK: Color = Color("#1d1d1f")
const WHITE: Color = Color("#fbfaf8")

const SKIN_TONES: Array[Color] = [Color("#f6d3b3"), Color("#e8b48a"), Color("#c98f66"), Color("#8d5a3b")]


## Darker, slightly cooler and more saturated variant.
static func shade(color: Color, amount: float = 0.18) -> Color:
	var result: Color = color
	result.h = wrapf(color.h + _hue_toward(color.h, 0.72) * amount * 0.35, 0.0, 1.0)
	result.s = clampf(color.s + amount * 0.25, 0.0, 1.0)
	result.v = clampf(color.v - amount, 0.0, 1.0)
	return result


## Lighter, slightly warmer and less saturated variant.
static func light(color: Color, amount: float = 0.14) -> Color:
	var result: Color = color
	result.h = wrapf(color.h + _hue_toward(color.h, 0.14) * amount * 0.35, 0.0, 1.0)
	result.s = clampf(color.s - amount * 0.3, 0.0, 1.0)
	result.v = clampf(color.v + amount, 0.0, 1.0)
	return result


static func outline_of(color: Color, strength: float) -> Color:
	var result: Color = shade(color, strength * 0.6)
	result.v = minf(result.v, 1.0 - strength)
	result.a = 1.0
	return result


## Signed shortest hue direction from `hue` toward `target`, in [-0.5, 0.5].
static func _hue_toward(hue: float, target: float) -> float:
	var delta: float = wrapf(target - hue, -0.5, 0.5)
	return clampf(delta * 4.0, -1.0, 1.0)
