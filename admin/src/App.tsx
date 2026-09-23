import { useCallback, useState } from "react";
import type { Session } from "@heroiclabs/nakama-js";
import { restoreSession, signOut } from "./api";
import { LoginForm } from "./LoginForm";
import { Dashboard } from "./Dashboard";

export function App() {
  const [session, setSession] = useState<Session | null>(() => restoreSession());

  const handleSignOut = useCallback(() => {
    if (session) {
      void signOut(session);
    }
    setSession(null);
  }, [session]);

  return (
    <div className="app">
      <header className="topbar">
        <span className="brand">
          OFFICE<span className="brand-accent">GAME</span> · админка
        </span>
        {session && (
          <button className="link" onClick={handleSignOut}>
            Выйти
          </button>
        )}
      </header>
      <main>{session ? <Dashboard session={session} onSessionLost={handleSignOut} /> : <LoginForm onSignedIn={setSession} />}</main>
    </div>
  );
}
