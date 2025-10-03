#!/usr/bin/env python3
"""
Script per ottimizzare gli asset esistenti di Ignition Mobile Tracker
- Aggiunge proprietà corrette per rendering template
- Configura compressione ottimale
- Prepara per uso con SF Symbols
"""

import os
import json
import glob

# Directory degli asset
assets_dir = "/Users/giuli1/Documents/app/Apple/ignition mobile tracker/Ignition Mobile Tracker/Ignition Mobile Tracker/Assets.xcassets"

# Asset che dovrebbero essere template (per tinting)
template_assets = [
    "home-tab", "tracker-tab", "missions-tab", "stats-tab",
    "spark-icon", "overload-icon", "streak-icon", "points-icon"
]

# Asset che dovrebbero mantenere i colori originali
original_assets = [
    "decisione-icon", "energia-icon", "idea-icon", "esperimento-icon", 
    "sfida-icon", "riflessione-icon", "intensity-low", "intensity-medium", 
    "intensity-high", "intensity-extreme", "mission-daily", "mission-weekly", 
    "mission-achievement", "fuel-gauge", "add-button", "profile-icon", 
    "calendar-icon", "tag-icon"
]

def update_asset_config(asset_name, is_template=False):
    """Aggiorna la configurazione di un asset"""
    asset_path = os.path.join(assets_dir, f"{asset_name}.imageset")
    contents_path = os.path.join(asset_path, "Contents.json")
    
    if not os.path.exists(contents_path):
        print(f"⚠️  Asset {asset_name} non trovato")
        return False
    
    try:
        with open(contents_path, 'r') as f:
            config = json.load(f)
        
        # Aggiorna le proprietà
        if "properties" not in config:
            config["properties"] = {}
        
        config["properties"]["compression-type"] = "automatic"
        
        if is_template:
            config["properties"]["template-rendering-intent"] = "template"
            config["properties"]["preserves-vector-representation"] = True
        else:
            config["properties"]["template-rendering-intent"] = "original"
            config["properties"]["preserves-vector-representation"] = True
        
        # Salva la configurazione aggiornata
        with open(contents_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"✅ Aggiornato {asset_name} ({'template' if is_template else 'original'})")
        return True
        
    except Exception as e:
        print(f"❌ Errore aggiornando {asset_name}: {e}")
        return False

def main():
    print("🎨 Ottimizzazione Asset Ignition Mobile Tracker")
    print("=" * 50)
    
    updated_count = 0
    
    # Aggiorna asset template
    print("\n📱 Aggiornamento Tab Icons e System Icons (template)...")
    for asset in template_assets:
        if update_asset_config(asset, is_template=True):
            updated_count += 1
    
    # Aggiorna asset con colori originali
    print("\n🎯 Aggiornamento Category e Feature Icons (original)...")
    for asset in original_assets:
        if update_asset_config(asset, is_template=False):
            updated_count += 1
    
    print(f"\n🎉 Ottimizzazione completata!")
    print(f"📊 Asset aggiornati: {updated_count}")
    print("\n💡 Raccomandazioni:")
    print("   • Converti JPEG in PNG per trasparenza")
    print("   • Verifica dimensioni: 25x25pt, 32x32pt, 24x24pt")
    print("   • Rimuovi background bianco per asset template")

if __name__ == "__main__":
    main()
