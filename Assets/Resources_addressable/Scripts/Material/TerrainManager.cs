using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;




public class TerrainHier1{
    public string ID;
    public string name;
    public string base_tile;              // ID, surface tile
    public float prob;
    public List<NoiseCfg> surface;
    public List<MineralInfo> minerals;           // ID, which mineral can be generated. The tile further back has a higher priority
}

public class MineralInfo{
    public string ID;
    public List<NoiseCfg> noise;
}


public class TerrainHierBase{
    // public List<NoiseCfg> x_noise;
    public List<NoiseCfg> Hier1;
    public float base_scale;
}

public class TerrainsInfo{
    public string version;
    public TerrainHierBase HierBase;
    public Dictionary<string, TerrainHier1> Hier1;
}

public class TerrainManager: BaseClass{
    public TerrainsInfo _infos;
    public Dictionary<string, TerrainHier1> _ID2TerrainHier1 = new();
    public List<TerrainHier1> _hier1s = new();
    public float[] _hier1s_prob;

    public TerrainManager(){
        load_all();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    void load_Hier1(string ID){
        _hier1s.Add(_infos.Hier1[ID]);
        _hier1s_prob[_hier1s.Count - 1] = _infos.Hier1[ID].prob;
        _ID2TerrainHier1.Add(ID, _infos.Hier1[ID]);
    }

    void load_all(){
        string jsonText = File.ReadAllText(_GCfg.__TerrainsInfo_path);
        _infos = JsonConvert.DeserializeObject<TerrainsInfo>(jsonText);
        rescale();
        _hier1s_prob = new float[_infos.Hier1.Count];
        foreach (var object_kv in _infos.Hier1){
            load_Hier1(object_kv.Key);
        }
    }

    void rescale(List<NoiseCfg> cfgs, bool isPrecondition){
        if (cfgs == null) return;
        foreach (var cfg in cfgs){
            rescale(cfg.precondition, true);
            rescale(cfg.x_noise, false);
            rescale(cfg.y_noise, false);
            cfg.f *= _infos.HierBase.base_scale;
            if (!isPrecondition) {
                cfg.min /= _infos.HierBase.base_scale;
                cfg.max /= _infos.HierBase.base_scale;
            }
        }
    }

    void rescale(){
        // float base_scale = _infos.HierBase.base_scale;
        rescale(_infos.HierBase.Hier1, true);
        foreach (var key in _infos.Hier1.Keys){
            rescale(_infos.Hier1[key].surface, false);
            for (int j = 0; j < _infos.Hier1[key].minerals.Count; j++){
                for (int k = 0; k < _infos.Hier1[key].minerals[j].noise.Count; k++){
                    rescale(_infos.Hier1[key].minerals[j].noise, true);
                }
            }
        }
        // for (int i = 0; i < _infos.HierBase.Hier1.Count; i++){
        //     _infos.HierBase.Hier1[i].f *= base_scale;
        //     for (int j = 0; j < _infos.HierBase.Hier1[i].precondition.Count; j++){
        //         _infos.HierBase.Hier1[i].y_noise[j].f *= base_scale;
        //     }
        //     for (int j = 0; j < _infos.HierBase.Hier1[i].x_noise.Count; j++){
        //         _infos.HierBase.Hier1[i].x_noise[j].min /= base_scale;
        //         _infos.HierBase.Hier1[i].x_noise[j].max /= base_scale;
        //         _infos.HierBase.Hier1[i].x_noise[j].f *= base_scale;
        //     }
        //     for (int j = 0; j < _infos.HierBase.Hier1[i].y_noise.Count; j++){
        //         _infos.HierBase.Hier1[i].y_noise[j].min /= base_scale;
        //         _infos.HierBase.Hier1[i].y_noise[j].max /= base_scale;
        //         _infos.HierBase.Hier1[i].y_noise[j].f *= base_scale;
        //     }
        // }
        // foreach (var key in _infos.Hier1.Keys){
        //     for (int j = 0; j < _infos.Hier1[key].surface.Count; j++){
        //         _infos.Hier1[key].surface[j].min /= base_scale;
        //         _infos.Hier1[key].surface[j].max /= base_scale;
        //         _infos.Hier1[key].surface[j].f *= base_scale;
        //     }
        //     for (int j = 0; j < _infos.Hier1[key].minerals.Count; j++){
        //         for (int k = 0; k < _infos.Hier1[key].minerals[j].noise.Count; k++){
        //             _infos.Hier1[key].minerals[j].noise[k].f *= base_scale;
        //         }
        //     }
        // }
    }
}
