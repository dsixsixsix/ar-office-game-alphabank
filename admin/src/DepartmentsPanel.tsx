import { useState, type FormEvent } from "react";
import { api, type Department, type User } from "./api";
import type { DashboardActions } from "./Dashboard";

export function DepartmentsPanel({ actions, players }: { actions: DashboardActions; players: User[] }) {
  const [name, setName] = useState("");

  async function create(event: FormEvent) {
    event.preventDefault();
    if (await actions.createDepartment(name)) {
      setName("");
    }
  }

  function rename(department: Department) {
    const next = window.prompt("Новое название департамента:", department.name);
    if (next && next.trim() !== department.name) {
      void actions.run(() => api.renameDepartment(actions.session, department.id, next));
    }
  }

  return (
    <section className="card">
      <h2>Департаменты</h2>
      <p className="muted">На департаментах строятся междепартаментные задания: знакомство и бинго с коллегами из других отделов.</p>
      <ul className="departments">
        {actions.departments.map((department) => (
          <li key={department.id}>
            <span>{department.name}</span>
            <span className="muted">{players.filter((user) => user.department_id === department.id).length} чел.</span>
            <button className="link" onClick={() => rename(department)}>
              переименовать
            </button>
          </li>
        ))}
      </ul>
      <form className="with-button" onSubmit={create}>
        <input placeholder="Новый департамент" value={name} onChange={(e) => setName(e.target.value)} maxLength={60} />
        <button type="submit" disabled={!name.trim()}>
          Добавить
        </button>
      </form>
    </section>
  );
}
