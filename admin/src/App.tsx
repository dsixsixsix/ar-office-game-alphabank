import { useCallback, useState } from "react";
import type { Session } from "@heroiclabs/nakama-js";
import { restoreSession, signOut } from "./api";
import { LoginForm } from "./LoginForm";
import { Dashboard } from "./Dashboard";
import { AlfaLogo } from "./AlfaLogo";

export function App() {
  const [session, setSession] = useState<Session | null>(() => restoreSession());

  const handleSignOut = useCallback(() => {
    if (session) {
      void signOut(session);
    }
    setSession(null);
  }, [session]);

  return (
    <>
      <header className="topbar">
        <div className="topbar-inner">
          <span className="brand">
            <AlfaLogo />
            <span>
              Alfa<span className="brand-accent">Game</span>
            </span>
            <span className="brand-sub">админка</span>
          </span>
          {session && (
            <button className="link" onClick={handleSignOut}>
              Выйти
            </button>
          )}
        </div>
      </header>
      <main className="app">{session ? <Dashboard session={session} onSessionLost={handleSignOut} /> : <LoginForm onSignedIn={setSession} />}</main>
    </>
  );
}
