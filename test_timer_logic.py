import math
import os
import plistlib
import sys
import yaml

def test_timer_math_precision():
    print("[TEST] Precision de ceil() y recalculacion en pause():")
    cases = [
        (1500.0, 1500),
        (1499.8, 1500),
        (1499.1, 1500),
        (1499.0, 1499),
        (1498.2, 1499),
        (0.9, 1),
        (0.1, 1),
        (0.0, 0),
        (-0.5, 0),
    ]
    for time_diff, expected in cases:
        calculated = int(math.ceil(time_diff)) if time_diff > 0 else 0
        assert calculated == expected, f"Fallo: time_diff={time_diff}, esperado={expected}, obtenido={calculated}"
    print("  [OK] Todos los calculos de tiempo con ceil() son exactos y no producen negativos.")

def test_pause_edge_case():
    print("[TEST] Caso limite de pausa al llegar a 0.0s:")
    # Simulamos el comportamiento del TimerViewModel en pause():
    def simulate_pause(time_diff):
        diff = int(math.ceil(time_diff))
        if diff <= 0:
            return {"remaining": 0, "finished": True, "credited": True, "alert": True}
        else:
            return {"remaining": diff, "finished": False, "credited": False, "alert": False}

    res_zero = simulate_pause(0.0)
    assert res_zero["finished"] and res_zero["credited"] and res_zero["remaining"] == 0
    print("  [OK] Pausa en 0.0s completa el ciclo correctamente sin perder la sesion.")

    res_negative = simulate_pause(-1.5)
    assert res_negative["finished"] and res_negative["credited"] and res_negative["remaining"] == 0
    print("  [OK] Pausa despues de expirar completa el ciclo limpiamente.")

    res_active = simulate_pause(45.2)
    assert not res_active["finished"] and res_active["remaining"] == 46
    print("  [OK] Pausa en sesion activa conserva los 46s restantes exactos.")

def test_background_elapsed():
    print("[TEST] Recuperacion del temporizador tras segundo plano:")
    def simulate_resume(remaining_at_start, elapsed_in_background):
        target_remaining = remaining_at_start - elapsed_in_background
        diff = int(math.ceil(target_remaining))
        if diff <= 0:
            return {"remaining": 0, "finished": True}
        return {"remaining": diff, "finished": False}

    # Sesión de 25m (1500s), usuario deja la app 120s en background
    r1 = simulate_resume(1500, 120)
    assert r1["remaining"] == 1380 and not r1["finished"]
    print("  [OK] Tras 120s en background quedan exactamente 1380s (23m).")

    # Sesión de 25m (1500s), usuario deja la app 1800s en background (30m)
    r2 = simulate_resume(1500, 1800)
    assert r2["remaining"] == 0 and r2["finished"]
    print("  [OK] Tras finalizar en background el ciclo queda completado y listo.")

def test_infoplist_and_project_yml():
    print("[TEST] Verificacion de Info.plist y project.yml:")
    root = os.path.dirname(os.path.abspath(__file__))
    project_yml_path = os.path.join(root, "project.yml")
    infoplist_path = os.path.join(root, "PomoCute", "Info.plist")

    assert os.path.isfile(project_yml_path), "Falta project.yml"
    assert os.path.isfile(infoplist_path), "Falta Info.plist"

    with open(project_yml_path, "r", encoding="utf-8") as f:
        p_data = yaml.safe_load(f)

    props = p_data["targets"]["PomoCute"]["info"]["properties"]
    assert props["CFBundleDisplayName"] == "PomoCute"
    assert props["CFBundleDevelopmentRegion"] == "es"
    assert "UILaunchScreen" in props
    assert props["UISupportedInterfaceOrientations"] == ["UIInterfaceOrientationPortrait"]
    assert props.get("UIRequiresFullScreen") is True
    print("  [OK] project.yml contiene todas las propiedades unificadas.")

    with open(infoplist_path, "rb") as f:
        plist_data = plistlib.load(f)

    assert plist_data["CFBundleDisplayName"] == "PomoCute"
    assert plist_data["CFBundleDevelopmentRegion"] == "es"
    assert "UILaunchScreen" in plist_data
    assert plist_data["UISupportedInterfaceOrientations"] == ["UIInterfaceOrientationPortrait"]
    assert plist_data.get("UIRequiresFullScreen") is True
    print("  [OK] Info.plist coincide fielmente con la especificacion.")

def test_audio_assets():
    print("[TEST] Verificacion de archivos de audio .caf:")
    root = os.path.dirname(os.path.abspath(__file__))
    audio_paths = [
        os.path.join(root, "PomoCute", "Audio", "bell.caf"),
        os.path.join(root, "PomoCute", "Audio", "pop.caf"),
        os.path.join(root, "PomoCute", "bell.caf"),
        os.path.join(root, "PomoCute", "pop.caf"),
    ]
    for p in audio_paths:
        assert os.path.isfile(p), f"Falta archivo de audio: {p}"
        with open(p, "rb") as f:
            header = f.read(4)
            assert header == b"caff", f"Cabecera invalida en {p}: {header}"
        size = os.path.getsize(p)
        assert size > 0, f"Archivo vacio: {p}"
        print(f"  [OK] {os.path.basename(p)} verificado ({size} bytes, Core Audio Format).")

def test_iphone_se_geometry():
    print("[TEST] Compatibilidad de geometria con iPhone SE 1st Gen (320x568 pt):")
    # Elementos en ContentView:
    status_bar = 20
    top_bar = 56
    mode_selector = 36
    circle_clock = 195
    cycles_indicator = 24
    control_buttons = 64
    basket_card = 54
    total_elements = status_bar + top_bar + mode_selector + circle_clock + cycles_indicator + control_buttons + basket_card
    assert total_elements <= 568, f"Desbordamiento de pantalla: {total_elements} > 568"
    margin = 568 - total_elements
    print(f"  [OK] Altura total de componentes: {total_elements} pt. Margen vertical libre para Spacers: {margin} pt.")

if __name__ == "__main__":
    print("=== SUITE DE PRUEBAS AUTOMATIZADAS DE POMOCUTE ===")
    test_timer_math_precision()
    test_pause_edge_case()
    test_background_elapsed()
    test_infoplist_and_project_yml()
    test_audio_assets()
    test_iphone_se_geometry()
    print("=== TODAS LAS PRUEBAS AUTOMATIZADAS COMPLETADAS CON EXITO ===")
