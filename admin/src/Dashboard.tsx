import { useCallback, useEffect, useState } from "react";
import type { Session } from "@heroiclabs/nakama-js";
import { api, type Department, type User } from "./api";
import { errorText, isSessionError } from "./messages";
import { CreateUserForm } from "./CreateUserForm";
import { UsersTable } from "./UsersTable";
import { DepartmentsPanel } from "./DepartmentsPanel";

export interface DashboardActions {
  session: Session;
  departments: Department[];
  /** Runs a server call, reloads the lists afterwards and reports errors. Resolves to false on error. */
  run: (action: () => Promise<unknown>) => Promise<boolean>;
  createDepartment: (name: string) => Promise<Department | null>;
}

export function Dashboard({ session, onSessionLost }: { session: Session; onSessionLost: () => void }) {
  const [departments, setDepartments] = useState<Department[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [error, setError] = useState("");

  const fail = useCallback(
    (e: unknown) => {
      if (isSessionError(e)) {
        onSessionLost();
      } else {
        setError(errorText(e));
      }
    },
    [onSessionLost],
  );

  const reload = useCallback(async () => {
    try {
      const [nextDepartments, nextUsers] = await Promise.all([api.listDepartments(session), api.listUsers(session)]);
      setDepartments(nextDepartments);
      setUsers(nextUsers);
    } catch (e) {
      fail(e);
    }
  }, [session, fail]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const run = useCallback(
    async (action: () => Promise<unknown>) => {
      setError("");
      try {
        await action();
        await reload();
        return true;
      } catch (e) {
        fail(e);
        return false;
      }
    },
    [reload, fail],
  );

  const createDepartment = useCallback(
    async (name: string) => {
      let created: Department | null = null;
      await run(async () => {
        created = await api.createDepartment(session, name);
      });
      return created;
    },
    [run, session],
  );

  const actions: DashboardActions = { session, departments, run, createDepartment };
  const players = users.filter((user) => user.role === "player");

  return (
    <div className="dashboard">
      {error && (
        <p className="error banner" onClick={() => setError("")}>
          {error}
        </p>
      )}
      <CreateUserForm actions={actions} />
      <UsersTable actions={actions} users={players} />
      <DepartmentsPanel actions={actions} players={players} />
    </div>
  );
}
