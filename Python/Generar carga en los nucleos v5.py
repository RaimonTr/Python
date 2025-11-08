import multiprocessing
import time
import sys
import random

BASE_DUTY = 0.15      # 15% por núcleo
SPREAD     = 0.05     # +/-5% de variación aleatoria alrededor de BASE_DUTY
PERIOD     = 0.1      # 100 ms por ciclo de control

def burn_for(duration_sec: int, base_duty: float, spread: float):
    """Genera carga con duty cycle variable en torno a base_duty ± spread."""
    end = time.time() + duration_sec
    while time.time() < end:
        duty = random.uniform(base_duty - spread, base_duty + spread)
        # Acotar a [0, 1]
        duty = max(0.0, min(1.0, duty))
        work_time = PERIOD * duty
        sleep_time = PERIOD - work_time

        t0 = time.time()
        # Fase de trabajo (busy loop)
        while (time.time() - t0) < work_time:
            pass
        # Fase de descanso
        if sleep_time > 0:
            time.sleep(sleep_time)
    
if __name__ == "__main__":
    cores = multiprocessing.cpu_count()
    print(f"Núcleos lógicos detectados: {cores}")

    # Núcleos a usar
    user_cores = input("Introduce número de núcleos a usar (Enter = todos): ").strip()
    if user_cores == "":
        workers = cores
    else:
        try:
            n = int(user_cores)
            workers = max(1, min(n, cores))
        except ValueError:
            workers = cores

    # Duración en minutos
    user_minutes = input("Introduce tiempo en minutos (Enter = 60): ").strip()
    if user_minutes == "":
        minutes = 60
    else:
        try:
            m = int(user_minutes)
            minutes = m if m > 0 else 60
        except ValueError:
            minutes = 60

    duration = minutes * 60

    # Estimado de carga total esperada
    frac = workers / cores
    est_low  = 100 * frac * max(0.0, BASE_DUTY - SPREAD)
    est_high = 100 * frac * min(1.0, BASE_DUTY + SPREAD)

    print(
        f"Usando {workers} núcleos de {cores} durante {minutes} minutos.\n"
        f"Carga aleatoria por núcleo ≈ {int((BASE_DUTY-SPREAD)*100)}%–{int((BASE_DUTY+SPREAD)*100)}%.\n"
        f"Estimación de carga total ≈ {est_low:.1f}% – {est_high:.1f}%."
    )

    processes = []
    try:
        for _ in range(workers):
            p = multiprocessing.Process(target=burn_for, args=(duration, BASE_DUTY, SPREAD))
            p.start()
            processes.append(p)

        # Contador regresivo HH:MM:SS
        remaining = duration
        while remaining > 0:
            hh, rem = divmod(remaining, 3600)
            mm, ss = divmod(rem, 60)
            sys.stdout.write(f"\rTiempo restante: {hh:02d}:{mm:02d}:{ss:02d}")
            sys.stdout.flush()
            time.sleep(1)
            remaining -= 1
        sys.stdout.write("\n")

    except KeyboardInterrupt:
        print("\nInterrumpido por el usuario. Deteniendo procesos...")

    finally:
        for p in processes:
            if p.is_alive():
                p.terminate()
        for p in processes:
            p.join()
        print("Carga finalizada.")
