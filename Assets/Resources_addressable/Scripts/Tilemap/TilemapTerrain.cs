using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using MathNet.Numerics.LinearAlgebra;


public class TilemapTerrain: BaseClass{
    List<TerrainHier2Info> _terrains_hier2 => _MatSys._terrain._terrains_hier2;
    List<TerrainHier1Info> _terrains_hier1 => _MatSys._terrain._terrains_hier1;
    public Dictionary<string, TerrainHier1Info> ID2TerrainHier1 => _MatSys._terrain._ID2TerrainHier1;
    public Dictionary<string[], TerrainHier2Info> tags2TerrainHier2 => _MatSys._terrain._tags2TerrainHier2;

    public TilemapTerrain() {
        // init_terrainsHier2Info();
        // init_terrainHier1Info();
        // init_ID2TerrainHier1Info();
        // init_tags2TerrainHier2();
    }

    public TilemapBlock _random_terrainHier1(TilemapBlock block, TilemapBlockAround around_blocks){
        List<string> terrains_avail = get_available_terrainsHier1(block);
        float[] terrains_prob = get_terrains_prob(terrains_avail, around_blocks);
        string terrain_ID = terrains_avail[RandomGenerator._random_by_prob(terrains_prob, block.offsets)];
        block.terrain_ID = terrain_ID;
        return block;
    }

    public TilemapBlock _random_terrainHier2_random(TilemapBlock block, TilemapBlockAround around_blocks){
        List<TerrainHier2Info> terrainTypes_avail = get_available_terrainHier2(block.terrain_ID);
        float[] terrainTypes_prob = get_terrainHier2_prob(terrainTypes_avail, around_blocks);
        string[] terrainTypes_tags = terrainTypes_avail[RandomGenerator._random_by_prob(terrainTypes_prob, block.offsets)].tags;
        block.terrain_tags = terrainTypes_tags;
        block.scale = tags2TerrainHier2[terrainTypes_tags].scale;
        return block;
    }

    List<TerrainHier2Info> get_available_terrainHier2(string terrain_ID){
        TerrainHier1Info terrain = ID2TerrainHier1[terrain_ID];
        List<TerrainHier2Info> types = new();
        for (int i = 0; i < _terrains_hier2.Count; i++){
            if (check_tagsIsSubset(terrain.tags, _terrains_hier2[i].tags))
                types.Add(_terrains_hier2[i]);
        }
        return types;
    }
    
    float[] get_terrainHier2_prob(List<TerrainHier2Info> types, TilemapBlockAround around_blocks){
        // init
        float[] probs = new float[types.Count];
        for(int i = 0; i < types.Count; i++){
            probs[i] = 1;
            // increase the prob of exist tags
            if(around_blocks.up.isExist && check_tagsIsSubset(around_blocks.up.terrain_tags, types[i].tags))           probs[i] += types.Count;
            if(around_blocks.down.isExist && check_tagsIsSubset(around_blocks.down.terrain_tags, types[i].tags))       probs[i] += types.Count;
            if(around_blocks.left.isExist && check_tagsIsSubset(around_blocks.left.terrain_tags, types[i].tags))       probs[i] += types.Count;
            if(around_blocks.right.isExist && check_tagsIsSubset(around_blocks.right.terrain_tags, types[i].tags))     probs[i] += types.Count;
        }
        return probs;
    }

    bool check_tagsIsSubset(string[] tags_sub, string[] tags_super){
        return tags_sub.All(item => tags_super.Contains(item));
    }

    bool check_terrainHier1_available(TilemapBlock block, TerrainHier1Info terrain){
        // height condition
        if (block.offsets.y < terrain.h_avail[0] && terrain.h_avail[0] != -999999999) return false;
        if (block.offsets.y >= terrain.h_avail[1] && terrain.h_avail[1] != 999999999) return false;
        // all pass
        return true;
    }

    List<string> get_available_terrainsHier1(TilemapBlock block){
        List<string> availables = new ();
        for(int i = 0; i < _terrains_hier1.Count; i++)
            if (check_terrainHier1_available(block, _terrains_hier1[i]))
                availables.Add(_terrains_hier1[i].ID);
        return availables;
    }
        
    float[] get_terrains_prob(List<string> terrains, TilemapBlockAround around_blocks){
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

    // int random_by_prob(float[] probs, Vector3Int offsets){
    //     int random_offset = offsets.x + offsets.y;
    //     float sum = probs.Sum();
    //     float target = Random.Range(random_offset, sum + random_offset) - random_offset;
    //     for(int i = 0; i < probs.Length; i++){
    //         target -= probs[i];
    //         if(target <= 0) return i;
    //     }
    //     return probs.Length - 1;
    // }

    // // ---------- init ----------
    // void init_ID2TerrainHier1Info(){
    //     for(int i = 0; i < _terrains_hier1.Count; i++){
    //         ID2TerrainHier1.Add(_terrains_hier1[i].ID, _terrains_hier1[i]);
    //     }
    // }

    // void init_tags2TerrainHier2(){
    //     for(int i = 0; i < _terrains_hier2.Count; i++){
    //         tags2TerrainHier2.Add(_terrains_hier2[i].tags, _terrains_hier2[i]);
    //     }
    // }

    // void init_terrainHier1Info(){
    //     _terrains_hier1.Add(new TerrainHier1Info{
    //         ID = "0", name = "plain", tags = new string[]{"flat", "ground"},
    //         h_avail = new int[]{-999999999, 999999999},
    //         surface = "b6", minerals = new string[] { "b3", "b4", "b5" }
    //     });
    //     _terrains_hier1.Add(new TerrainHier1Info{
    //         ID = "1", name = "sky", tags = new string[]{"sky"},
    //         h_avail = new int[]{100, 999999999},
    //         surface = _GCfg._empty_tile, minerals = new string[]{}
    //     });
    //     _terrains_hier1.Add(new TerrainHier1Info{
    //         ID = "2", name = "underground gravel", tags = new string[]{"underground"},
    //         h_avail = new int[]{-999999999, -3},
    //         surface = "b3", minerals = new string[] {"b4"}
    //     });
    // }

    // void init_terrainsHier2Info(){
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"flat", "ground"},
    //         name = "flat ground", scale = 1f, isExist=true,
    //         dirs_avail = new string[] { "0", "1", "2",   "3", "4", "5",  "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[] { 0.1f, 1, 50,   1, 0.1f, 5,   0.1f, 1, 1,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f},
    //     });
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"undulating", "ground"},
    //         name = "undulating ground", scale = 2f, isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[] {0.1f, 10, 10,   10, 1, 10,   1, 10, 10,   0.1f, 0.1f, 0.1f,   1, 1, 0.1f,   0.1f },
    //     });
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"steep", "ground"},
    //         name = "steep ground", scale = 4f, isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[] {0.1f, 10, 10,   10, 10, 10,   10, 10, 10,   1, 1, 1,   10, 10, 1,   1 },
    //     });
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"suspended", "ground"},
    //         name = "suspended ground", scale = 4f, isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[] {0.1f, 10, 1,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10 },
    //     });
        
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"spacious", "underground"},
    //         name = "spacious underground", scale = 1f,  isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[]   { 10, 1, 50,   1, 10, 1,   10, 1, 1,   1, 1, 1,   10, 10, 1,   1 },
    //     });
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"roomy", "underground"},
    //         name = "roomy underground", scale = 2f,  isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[]   { 10, 10, 10,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10, 10, 10,   10 },
    //     });
    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"narrow", "underground"},
    //         name = "narrow underground", scale = 4f,  isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19" },
    //         dirs_prob = new float[]   { 1, 10, 1,   10, 1, 50,   1, 10, 10,   10, 10, 10,   1, 1, 10,   10 },
    //     });

    //     _terrains_hier2.Add(new TerrainHier2Info {
    //         tags = new string[] {"sky"},
    //         name = "sky", scale = 1f, isExist=true,
    //         dirs_avail = new string[] {"0", "1", "2",   "3", "4", "5",   "6", "7", "9",   "11", "12", "13",   "14", "16", "17",   "19"},
    //         dirs_prob = new float[] {50, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f,   0.1f, 0.1f, 0.1f, 0.1f},
    //     });
    // }

}