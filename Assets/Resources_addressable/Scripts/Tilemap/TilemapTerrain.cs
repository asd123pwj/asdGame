using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using MathNet.Numerics.LinearAlgebra;


/*
 * ---------- type of terrain ----------
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
public struct TerrainType{
    public string[] tags;
    public string name;
    public float scale;
    public string[] dirs_avail;         // available directions
    public float[] dirs_prob;           // probability of each available directions
    public bool isExist;
}

public struct TerrainInfo{
    public string ID;
    public string name;
    public string[] tags;
    public int[] h_avail;               // where can it generating, height means block offset, left close right open interval
    public int surface;              // ID, surface tile
    // public string tile_transition;      // ID, transition from terr1 to terr2, trans_tile is the surface_tile of terr2
    public int[] minerals;           // ID, which mineral can be generated. The tile further back has a higher priority
    public bool isExist;
}

public class TilemapTerrain{
    List<TerrainType> _terrains_type = new();
    List<TerrainInfo> _terrains_info = new();
    public Dictionary<string, TerrainInfo> ID2TerrainInfo = new();
    public Dictionary<string[], TerrainType> tags2TerrainType = new();

    public TilemapTerrain() {
        init_terrainsType();
        init_terrainsInfo();
        init_ID2TerrainInfo();
        init_tags2TerrainType();
    }

    public TilemapBlock _set_terrain_random(TilemapBlock block, TilemapAroundBlock around_blocks){
        List<string> terrains_avail = get_available_terrains(block);
        float[] terrains_prob = get_terrains_prob(terrains_avail, around_blocks);
        string terrain_ID = terrains_avail[random_by_prob(terrains_prob)];
        block.terrain_ID = terrain_ID;
        return block;
    }

    public TilemapBlock _set_terrainType_random(TilemapBlock block, TilemapAroundBlock around_blocks){
        List<TerrainType> terrainTypes_avail = get_available_terrainTypes(block.terrain_ID);
        float[] terrainTypes_prob = get_terrainTypes_prob(terrainTypes_avail, around_blocks);
        string[] terrainTypes_tags = terrainTypes_avail[random_by_prob(terrainTypes_prob)].tags;
        block.terrainType_tags = terrainTypes_tags;
        block.scale = tags2TerrainType[terrainTypes_tags].scale;
        return block;
    }

    List<TerrainType> get_available_terrainTypes(string terrain_ID){
        TerrainInfo terrain = ID2TerrainInfo[terrain_ID];
        List<TerrainType> types = new();
        for (int i = 0; i < _terrains_type.Count; i++){
            if (check_tagsIsSubset(terrain.tags, _terrains_type[i].tags))
                types.Add(_terrains_type[i]);
        }
        return types;
    }
    
    float[] get_terrainTypes_prob(List<TerrainType> types, TilemapAroundBlock around_blocks){
        // init
        float[] probs = new float[types.Count];
        for(int i = 0; i < types.Count; i++){
            probs[i] = 1;
            // increase the prob of exist tags
            if(around_blocks.up.isExist && check_tagsIsSubset(around_blocks.up.terrainType_tags, types[i].tags))           probs[i] += types.Count;
            if(around_blocks.down.isExist && check_tagsIsSubset(around_blocks.down.terrainType_tags, types[i].tags))       probs[i] += types.Count;
            if(around_blocks.left.isExist && check_tagsIsSubset(around_blocks.left.terrainType_tags, types[i].tags))       probs[i] += types.Count;
            if(around_blocks.right.isExist && check_tagsIsSubset(around_blocks.right.terrainType_tags, types[i].tags))     probs[i] += types.Count;
        }
        return probs;
    }

    bool check_tagsIsSubset(string[] tags_sub, string[] tags_super){
        return tags_sub.All(item => tags_super.Contains(item));
    }

    bool check_terrainAvailable(TilemapBlock block, TerrainInfo terrain){
        // height condition
        if (block.offsets.y < terrain.h_avail[0] && terrain.h_avail[0] != -999999999) return false;
        if (block.offsets.y >= terrain.h_avail[1] && terrain.h_avail[1] != 999999999) return false;
        // all pass
        return true;
    }

    List<string> get_available_terrains(TilemapBlock block){
        List<string> availables = new ();
        for(int i = 0; i < _terrains_info.Count; i++)
            if (check_terrainAvailable(block, _terrains_info[i]))
                availables.Add(_terrains_info[i].ID);
        return availables;
    }
        
    float[] get_terrains_prob(List<string> terrains, TilemapAroundBlock around_blocks){
        // init
        float[] probs = new float[terrains.Count];
        for(int i = 0; i < terrains.Count; i++){
            probs[i] = 1;
            // increase the prob of exist terrain
            if(around_blocks.up.isExist && terrains[i]==around_blocks.up.terrain_ID)          probs[i] += terrains.Count * 2;
            if(around_blocks.down.isExist && terrains[i]==around_blocks.down.terrain_ID)      probs[i] += terrains.Count * 2;
            if(around_blocks.left.isExist && terrains[i]==around_blocks.left.terrain_ID)      probs[i] += terrains.Count * 2;
            if(around_blocks.right.isExist && terrains[i]==around_blocks.right.terrain_ID)    probs[i] += terrains.Count * 2;
        }
        return probs;
    }
    

    // ---------- other ----------

    int random_by_prob(float[] probs){
        float sum = probs.Sum();
        float target = Random.Range(0f, sum);
        for(int i = 0; i < probs.Length; i++){
            target -= probs[i];
            if(target <= 0) return i;
        }
        return probs.Length - 1;
    }

    // ---------- init ----------
    void init_ID2TerrainInfo(){
        for(int i = 0; i < _terrains_info.Count; i++){
            ID2TerrainInfo.Add(_terrains_info[i].ID, _terrains_info[i]);
        }
    }

    void init_tags2TerrainType(){
        for(int i = 0; i < _terrains_type.Count; i++){
            tags2TerrainType.Add(_terrains_type[i].tags, _terrains_type[i]);
        }
    }

    void init_terrainsInfo(){
        _terrains_info.Add(new TerrainInfo{
            ID = "0", name = "plain", tags = new string[]{"flat", "ground"},
            h_avail = new int[]{-999999999, 999999999},
            surface = 1, minerals = new int[] { 3, 2 }
        });
        _terrains_info.Add(new TerrainInfo{
            ID = "1", name = "sky", tags = new string[]{"sky"},
            h_avail = new int[]{100, 999999999},
            surface = 0, minerals = new int[]{}
        });
        _terrains_info.Add(new TerrainInfo{
            ID = "2", name = "underground gravel", tags = new string[]{"underground"},
            h_avail = new int[]{-999999999, -3},
            surface = 3, minerals = new int[] {2}
        });
    }

    void init_terrainsType(){
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"flat", "ground"},
            name = "flat ground", scale = 1f, isExist=true,
            dirs_avail = new string[] { "0", "1", "2",   "3", "4", "5",  "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[] { 0.1f, 1, 50,   1, 0.1f, 5,   0.1f, 1, 1,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f},
        });
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"undulating", "ground"},
            name = "undulating ground", scale = 2f, isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[] {0.1f, 10, 10,   10, 1, 10,   1, 10, 10,   0.1f, 0.1f, 0.1f,   1, 1, 0.1f,   0.1f },
        });
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"steep", "ground"},
            name = "steep ground", scale = 4f, isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[] {0.1f, 10, 10,   10, 10, 10,   10, 10, 10,   1, 1, 1,   10, 10, 1,   1 },
        });
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"suspended", "ground"},
            name = "suspended ground", scale = 4f, isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[] {0.1f, 10, 1,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10 },
        });
        
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"spacious", "underground"},
            name = "spacious underground", scale = 1f,  isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[]   { 10, 1, 50,   1, 10, 1,   10, 1, 1,   1, 1, 1,   10, 10, 1,   1 },
        });
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"roomy", "underground"},
            name = "roomy underground", scale = 2f,  isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[]   { 10, 10, 10,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10 },
        });
        _terrains_type.Add(new TerrainType {
            tags = new string[] {"narrow", "underground"},
            name = "narrow underground", scale = 4f,  isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
            dirs_prob = new float[]   { 1, 10, 1,   10, 1, 50,   1, 10, 10,   10, 10, 10,   1, 1, 10,   10 },
        });

        _terrains_type.Add(new TerrainType {
            tags = new string[] {"sky"},
            name = "sky", scale = 1f, isExist=true,
            dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19"},
            dirs_prob = new float[] {50, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f, 0.1f},
        });
    }

}