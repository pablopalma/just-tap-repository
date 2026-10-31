"""Balance report from the beta play data (docs/beta-datos.md).

Download the sheet as CSV (File → Download → .csv) and run:

    python tools/beta_report.py events.csv [--version 0.9.0-beta] [--out Builds/beta_report.md]

It answers the questions tools/sim_time answers, but with real players: how long each barrier
takes, where people get stuck, where they leave, and what they buy in the tree.
"""
import argparse
import csv
import json
import statistics
import sys
from collections import Counter, defaultdict

SLOW = 90.0  # seconds: tools/sim_time keeps the worst barrier around 1.5 min


def pct(values, q):
    if not values:
        return 0.0
    v = sorted(values)
    i = min(len(v) - 1, max(0, int(round(q * (len(v) - 1)))))
    return v[i]


def fmt_s(s):
    return f"{s / 60:.1f} min" if s >= 120 else f"{s:.0f} s"


def load(path, version):
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if version and r["version"] != version:
                continue
            try:
                r["d"] = json.loads(r["data"] or "{}")
            except ValueError:
                r["d"] = {}
            r["n"] = int(float(r["barrier"] or 0))
            r["t"] = float(r["t"] or 0)
            rows.append(r)
    return rows


def report(rows):
    out = []
    say = out.append
    players = {r["uid"] for r in rows}
    sessions = {r["session"] for r in rows}
    by_uid = defaultdict(list)
    for r in rows:
        by_uid[r["uid"]].append(r)
    plats = Counter()
    for uid, rs in by_uid.items():
        plats[rs[0]["platform"]] += 1
    finished = {r["uid"] for r in rows if r["event"] == "demo_end"}
    started = {r["uid"] for r in rows if r["event"] == "start"}
    opted_out = {r["uid"] for r in rows if r["event"] == "opt_out"}

    say("# Just Tap: reporte de la beta\n")
    say(f"- Jugadores: **{len(players)}** · sesiones: {len(sessions)} · "
        + " · ".join(f"{p}: {c}" for p, c in plats.most_common()))
    say(f"- Empezaron a jugar: {len(started)} · terminaron la demo: **{len(finished)}**"
        + (f" ({100 * len(finished) / max(1, len(started)):.0f} %)" if started else ""))
    if opted_out:
        say(f"- Apagaron los datos: {len(opted_out)}")

    # Per barrier: the first time each player broke it.
    gate = defaultdict(dict)  # n -> uid -> data
    for r in rows:
        if r["event"] == "gate" and r["uid"] not in gate[r["n"]]:
            gate[r["n"]][r["uid"]] = r["d"]
    totals = defaultdict(float)
    for n, per in gate.items():
        for uid, d in per.items():
            totals[uid] += float(d.get("s", 0))
    done_times = [totals[u] for u in finished if u in totals]
    if done_times:
        say(f"- Tiempo hasta el final de la demo: mediana **{fmt_s(statistics.median(done_times))}**, "
            f"rápido {fmt_s(pct(done_times, 0.1))}, lento {fmt_s(pct(done_times, 0.9))}")

    say("\n## Tiempo por barrera\n")
    say("Solo la primera vez que cada jugador la rompe. Las marcadas con ⚠ tardan más de "
        f"{SLOW:.0f} s en la mediana o más de {2 * SLOW:.0f} s para uno de cada cuatro.\n")
    say("| Barrera | Jugadores | Mediana | 75 % | Máx. | Toques (mediana) | Abrió el árbol | Cinemática |")
    say("|---:|---:|---:|---:|---:|---:|---:|---:|")
    slow = []
    for n in sorted(gate):
        per = gate[n]
        s = [float(d.get("s", 0)) for d in per.values()]
        taps = [int(d.get("taps", 0)) for d in per.values()]
        tree = sum(1 for d in per.values() if int(d.get("tree", 0)) > 0)
        cine = sum(1 for d in per.values() if d.get("cine"))
        med, p75 = statistics.median(s), pct(s, 0.75)
        flag = " ⚠" if med > SLOW or p75 > 2 * SLOW else ""
        if flag:
            slow.append(n)
        say(f"| {n}{flag} | {len(per)} | {fmt_s(med)} | {fmt_s(p75)} | {fmt_s(max(s))} | "
            f"{statistics.median(taps):.0f} | {100 * tree / len(per):.0f} % | {100 * cine / len(per):.0f} % |")

    # Where they leave: the barrier each player was on when we last heard from them.
    say("\n## Dónde dejan de jugar\n")
    say("La barrera en la que estaba cada jugador que no terminó la demo, según su último evento.\n")
    left = Counter()
    stuck = {}
    for uid, rs in by_uid.items():
        if uid in finished or uid not in started:
            continue
        last = max(rs, key=lambda r: (r["received"], r["t"]))
        left[last["n"]] += 1
        ticks = [r for r in rs if r["event"] in ("tick", "leave") and r["n"] == last["n"]]
        if ticks:
            stuck[uid] = max(float(r["d"].get("s", 0)) for r in ticks)
    if left:
        say("| Barrera | Jugadores | Tiempo en esa barrera (mediana) |")
        say("|---:|---:|---:|")
        for n, c in sorted(left.items()):
            waits = [stuck[u] for u, rs in by_uid.items() if u in stuck and
                     max(rs, key=lambda r: (r["received"], r["t"]))["n"] == n]
            say(f"| {n} | {c} | {fmt_s(statistics.median(waits)) if waits else '—'} |")
    else:
        say("Nadie todavía.")

    # The tree.
    say("\n## Árbol de mejoras\n")
    buys = [r for r in rows if r["event"] == "buy"]
    first_at = defaultdict(dict)   # id -> uid -> barrier of first purchase
    top = defaultdict(dict)        # id -> uid -> highest level
    for r in buys:
        i = r["d"].get("id", "?")
        first_at[i].setdefault(r["uid"], r["n"])
        top[i][r["uid"]] = max(top[i].get(r["uid"], 0), int(r["d"].get("lv", 0)))
    if first_at:
        say("| Mejora | Jugadores | Primera compra (barrera, mediana) | Nivel alcanzado (mediana) |")
        say("|---|---:|---:|---:|")
        for i in sorted(first_at, key=lambda k: -len(first_at[k])):
            say(f"| {i} | {len(first_at[i])} | {statistics.median(first_at[i].values()):.0f} | "
                f"{statistics.median(top[i].values()):.0f} |")
    trees = [float(r["d"].get("s", 0)) for r in rows if r["event"] == "tree"]
    if trees:
        say(f"\nVeces que abren el árbol: {len(trees)} · tiempo adentro: mediana {fmt_s(statistics.median(trees))}")

    say("\n## Para revisar\n")
    if slow:
        say("- Barreras lentas: " + ", ".join(str(n) for n in slow)
            + ". Compararlas con `tools/sim_time` y bajar su vida o subir la luz que dan las anteriores.")
    if left:
        worst = left.most_common(1)[0]
        say(f"- Donde más gente deja: barrera {worst[0]} ({worst[1]} jugadores).")
    if not slow and not left:
        say("- Nada fuera de lo esperado todavía.")
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv")
    ap.add_argument("--version", default="")
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    text = report(load(a.csv, a.version))
    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"Reporte en {a.out}")
    else:
        sys.stdout.reconfigure(encoding="utf-8")
        print(text)


if __name__ == "__main__":
    main()
