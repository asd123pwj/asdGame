using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;



/*
 * ---------- type of terrainHier1 ----------
 * ---------- direction fluctuation
 * flat: 2
 * undulating: 1 3 7 9
 * steep: 4 6 14 16
 * suspended: 11 12 13 17 19
 * full: 5
 * empty: 0
 * ---------- ground
 * |    tag     |  flat  |  undulating  |  steep  |  suspended  |  full  |  empty  |
 * |------------|--------|--------------|---------|-------------|--------|---------|
 * |    flat    |  most  |     few      |   no    |     no      |  some  |   no    |
 * | undulating |  some  |     some     |   few   |     no      |  some  |   no    |
 * |   steep    |  some  |     some     |   some  |     few     |  some  |   no    |
 * |  suspended |  few   |     some     |   some  |     some    |  some  |   no    |
 *
 * ---------- underground
 * |    tag     |  flat  |  undulating  |  steep  |  suspended  |  full  |  empty  |
 * |------------|--------|--------------|---------|-------------|--------|---------|
 * |  spacious  |  most  |     few      |   some  |     few     |  few   |   some  |
 * |  roomy     |  some  |     some     |   some  |     some    |  some  |   some  |
 * |  narrow    |  few   |     some     |   few   |     some    |  most  |   few   |
 *
 * ---------- sky
 * |    tag     |  flat  |  undulating  |  steep  |  suspended  |  full  |  empty  |
 * |------------|--------|--------------|---------|-------------|--------|---------|
 * |    sky     |   no   |      no      |    no   |     no      |   no   |   most  |
 *
 */
public struct TerrainHier2Info{
    public string[] tags;
    public string name;
    public float scale;
    public string[] dirs_avail;         // available directions
    public float[] dirs_prob;           // probability of each available directions
    // public bool isExist;
}

public struct TerrainHier1Info{
    public string ID;
    public string name;
    public string[] tags;
    public int[] h_avail;               // where can it generating, height means block offset, left close right open interval
    public string surface;              // ID, surface tile
    // public string tile_transition;      // ID, transition from terr1 to terr2, trans_tile is the surface_tile of terr2
    public string[] minerals;           // ID, which mineral can be generated. The tile further back has a higher priority
    // public bool isExist;
}

public struct TerrainsInfo{
    public string version;
    public Dictionary<string, TerrainHier1Info> Hier1;
    public Dictionary<string, TerrainHier2Info> Hier2;
}

public class TerrainManager: BaseClass{
    public TerrainsInfo _infos;
    public List<TerrainHier2Info> _terrains_hier2 = new();
    public List<TerrainHier1Info> _terrains_hier1 = new();
    public Dictionary<string, TerrainHier1Info> _ID2TerrainHier1 = new();
    public Dictionary<string[], TerrainHier2Info> _tags2TerrainHier2 = new();

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
        _terrains_hier1.Add(_infos.Hier1[ID]);
        _ID2TerrainHier1.Add(ID, _infos.Hier1[ID]);
    }

    void load_Hier2(string ID){
        _terrains_hier2.Add(_infos.Hier2[ID]);
        _tags2TerrainHier2.Add(_infos.Hier2[ID].tags, _infos.Hier2[ID]);
    }

    void load_all(){
        string jsonText = File.ReadAllText(_GCfg.__TerrainsInfo_path);
        _infos = JsonConvert.DeserializeObject<TerrainsInfo>(jsonText);
        foreach (var object_kv in _infos.Hier1){
            load_Hier1(object_kv.Key);
        }
        foreach (var object_kv in _infos.Hier2){
            load_Hier2(object_kv.Key);
        }
    }
}
