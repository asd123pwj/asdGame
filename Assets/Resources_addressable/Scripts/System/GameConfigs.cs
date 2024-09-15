using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Newtonsoft.Json;


public struct SaveConfig{
    public string version;
    public string name;
}

public struct SystemConfig{
    // ---------- system config ----------
    // ----- config
    public string version;
    public string save_playing;
    // ---------- tilemap config ----------
    public Vector3Int TMap_tiles_per_block;         // how many tiles in one block, axis-z is no support
    // ----- loading
    public int TMap_tiles_per_loading;              // when loading, how many tiles in one time
    public int TMap_interval_per_loading;           // when loading, how long to wait between each loading
    public Vector3Int TMap_blocks_around_loading;   // when loading, how many blocks around the player to load

    public Vector3Int TMap_tileNeighborsCheck_max; // how far can be check, neighbor of RuleTile, only use to load placeholder.

    // ---------- Camera ----------
    // ----- player camera
    public float CAM_rowTiles_in_playerCamera_max;
    public float CAM_rowTiles_in_playerCamera_min;
    public float CAM_rowTiles_in_playerCamera_default;

    public int seed;
}


public class GameConfigs{
    public SystemManager _sys;
    // ---------- System Tools ----------
    public ControlSystem _CtrlSys { get { return _sys._CtrlSys; } }
    public InputSystem _InputSys { get { return _sys._InputSys; } }
    public TilemapSystem _TMapSys { get { return _sys._TMapSys; } }
    public ObjectSystem _ObjSys { get { return _sys._ObjSys; } }
    public UISystem _UISys { get { return _sys._UISys; } }
    public MaterialSystem _MatSys { get => _sys._MatSys; }
    public UpdateSystem _UpdateSys { get => _sys._UpdateSys; }

    // ---------- Tools ----------
    public Noise _noise;

    // ---------- system config ----------
    // config
    public string __version = "0.17.2b";
    public string __save_playing = "";
    // path
    string root_dir_editor = "Assets/Configs";
    string root_dir_build = "Configs";
    public string __root_dir => Application.isEditor ? root_dir_editor : root_dir_build;
    // public string __root_dir__ = "";
    public string __sysConfig_path { get { return Path.Combine(__root_dir, "Configs.json"); } }
    public string __tilesInfo_path { get { return Path.Combine(__root_dir, "TilesInfo.json"); } }
    public string __objectsInfo_path { get { return Path.Combine(__root_dir, "ObjectsInfo.json"); } }
    public string __UISpritesInfo_path { get { return Path.Combine(__root_dir, "UISpritesInfo.json"); } }
    public string __UIPrefabsInfo_path { get { return Path.Combine(__root_dir, "UIPrefabsInfo.json"); } }
    public string __MaterialsInfo_path { get { return Path.Combine(__root_dir, "MaterialsInfo.json"); } }
    public string __MeshesInfo_path { get { return Path.Combine(__root_dir, "MeshesInfo.json"); } }
    public string __PhysicsMaterialsInfo_path { get { return Path.Combine(__root_dir, "PhysicsMaterialsInfo.json"); } }

    // ---------- tilemap config ----------
    public string _empty_tile => "0";
    // public Vector3Int __block_size { get {return new Vector3Int(32, 32, 1); } }
    // public Vector3Int _TMap_tiles_per_block { get { return _sysCfg.TMap_tiles_per_block; } }
    // public int _TMap_tiles_per_loading { get { return _sysCfg.TMap_tiles_per_loading; } }
    // public int _TMap_interval_per_loading { get { return _sysCfg.TMap_interval_per_loading; } }
    public int __block_loadBound { get {return 10; } }
    public int __block_unloadBound { get {return 10; } }

    // ---------- save config ----------
    // config
    public string __save_selected = "";
    // path
    public string __saves_dir { get { return Path.Combine(__root_dir, "Saves"); } }
    public string __save_dir { get { return Path.Combine(__saves_dir, __save_selected); } }
    public string __saveConfig_path { get { return Path.Combine(__save_dir, "Configs.json"); } }
    public string __map_dir {get { return Path.Combine(__save_dir, "map"); } }
    public string __UI_dir {get { return Path.Combine(__save_dir, "UI"); } }
    public string __UI_path {get { return Path.Combine(__UI_dir, "UIInfos.json"); } }
    // format
    public string __mapName_format { get { return Path.Combine(__map_dir, "Map_{x}_{y}.json"); } }
    

    public SystemConfig _sysCfg;
    private Dictionary<string, SaveConfig> __saves_config;

    public GameConfigs(SystemManager sys){
        _sys = sys;
        // _sys = GameObject.Find("System").GetComponent<SystemManager>();
        // _sys._GCfg = this;
        _load_system_config();
        set_random(_sysCfg.seed);
        _load_saves_config();
        _init_save_config("test");
        select_save("test");

    }

    // ---------- System config ----------

    void set_random(int seed){
        UnityEngine.Random.InitState(seed);
        _noise = new(seed);
    }

    public void select_save(string name){
        _sysCfg.save_playing = name;
        __save_selected = name;
        __save_playing = name;
    }

    private void _init_system_config(){
        _sysCfg = new SystemConfig();
        _sysCfg.version = __version;
        _sysCfg.save_playing = "";
        string system_config_json = JsonConvert.SerializeObject(_sysCfg, Formatting.Indented);
        File.WriteAllText(__sysConfig_path, system_config_json);
    }

    private void _load_system_config(){
        if (File.Exists(__sysConfig_path)){ // load
            string jsonText = File.ReadAllText(__sysConfig_path);
            _sysCfg = JsonConvert.DeserializeObject<SystemConfig>(jsonText);
        }
        else{ // init
            _init_system_config();
        }
    }


    // ---------- Save config ----------

    private SaveConfig _init_save_config(string name){
        SaveConfig save_config = new SaveConfig();
        if (name == "")
            throw new System.Exception("Name of save is EMPTY.");
        else if (__saves_config.ContainsKey(name))
            return __saves_config[name];
        save_config.version = __version;
        save_config.name = name;
        __save_selected = name;
        Directory.CreateDirectory(__map_dir);
        string save_config_json = JsonConvert.SerializeObject(save_config, Formatting.Indented);
        File.WriteAllText(__saveConfig_path, save_config_json);

        __saves_config.Add(name, save_config);
        return save_config;
    }

    private void _load_saves_config(){
        // Init, and get all saves ("dir name" == "save name")
        __saves_config = new Dictionary<string, SaveConfig>();
        string[] saves_name = Directory.GetDirectories(__saves_dir);

        // Loop for load config of save
        
        foreach (string save_name in saves_name){
            __save_selected = Path.GetFileName(save_name);
            string jsonText = File.ReadAllText(__saveConfig_path);
            SaveConfig save_configs = JsonConvert.DeserializeObject<SaveConfig>(jsonText);
            __saves_config.Add(__save_selected, save_configs);
        }
    }
}
