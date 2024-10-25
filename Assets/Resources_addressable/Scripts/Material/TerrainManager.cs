using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;




public struct TerrainHier1Info{
    public string ID;
    public string name;
    public string surface;              // ID, surface tile
    public float prob;
    // public List<string[]> frequency;         // ["noise process type", "frequency", "scale"]
    public List<SurfaceFrequency> frequency;
    // public string[] minerals;           // ID, which mineral can be generated. The tile further back has a higher priority
    public List<MineralFrequency> minerals;           // ID, which mineral can be generated. The tile further back has a higher priority
}

public struct SurfaceFrequency{
    public string keep; // keep which part? "+": positive noise, "-": negative noise, other: keep all
    public float f; // frequency
    public int s; // scale, range of height: [-s*noise, s*noise]
}

public struct MineralFrequency{
    public string ID; // mineral ID
    public float f; // frequency
    public float t; // noise threshold
}

public struct TerrainsInfo{
    public string version;
    public Dictionary<string, TerrainHier1Info> Hier1;
}

public class TerrainManager: BaseClass{
    public TerrainsInfo _infos;
    // public List<TerrainHier2Info> _terrains_hier2 = new();
    public Dictionary<string, TerrainHier1Info> _ID2TerrainHier1 = new();
    // public List<string> _Hier1s = new();
    public List<TerrainHier1Info> _hier1s = new();
    public float[] _hier1s_prob;
    // public Dictionary<string[], TerrainHier2Info> _tags2TerrainHier2 = new();

    public TerrainManager(){
        load_all();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    // public bool _check_Hier1_exist(string ID){
    //     return _infos.Hier1.ContainsKey(ID);
    // }

    // public bool _check_loaded(string ID){
    //     return _ID2PhysicsMaterial2D.ContainsKey(ID);
    // }

    // public PhysicsMaterial2D _get_phyMat(string ID){
    //     return _ID2PhysicsMaterial2D[ID];
    // }

    // void load_item(string ID){
        // PhysicsMaterial2D item = new() { 
        //     friction = _infos.items[ID].friction,
        //     bounciness = _infos.items[ID].bounciness
        // };
        // _ID2PhysicsMaterial2D.Add(ID, item);
    // }

    void load_Hier1(string ID){
        _hier1s.Add(_infos.Hier1[ID]);
        _hier1s_prob[_hier1s.Count - 1] = _infos.Hier1[ID].prob;
        _ID2TerrainHier1.Add(ID, _infos.Hier1[ID]);
    }

    // void load_Hier2(string ID){
    //     _terrains_hier2.Add(_infos.Hier2[ID]);
    //     _tags2TerrainHier2.Add(_infos.Hier2[ID].tags, _infos.Hier2[ID]);
    // }

    void load_all(){
        string jsonText = File.ReadAllText(_GCfg.__TerrainsInfo_path);
        _infos = JsonConvert.DeserializeObject<TerrainsInfo>(jsonText);
        _hier1s_prob = new float[_infos.Hier1.Count];
        foreach (var object_kv in _infos.Hier1){
            load_Hier1(object_kv.Key);
        }
        // foreach (var object_kv in _infos.Hier2){
        //     load_Hier2(object_kv.Key);
        // }
    }
}
