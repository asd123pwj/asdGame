using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Video;
using System.Diagnostics;


public class TilemapBlockGenerate: BaseClass{
    TilemapConfig TMapCfg { get => _TMapSys._TMapCfg; }
    // GameConfigs _GCfg;
    // DirectionsConfig DirCfg = new();
    TilemapBlockAround BAround;
    TilemapBlockDirection BDir;
    TilemapTerrain _terrain;
    TilemapBlockMineral _block_mineral;
    // TilemapSaveLoad _saveLoad;
    // TilemapBlockTransition _block_transition;

    public TilemapBlockGenerate(){
        // _tilemap_base = tilemap_base;
        // _GCfg = game_configs;
        _terrain = new();
        BAround = new(_terrain);
        BDir = new();
        _block_mineral = new(_terrain);
        // _block_transition = new(_tilemap_base, _game_configs, _terrain);
    }

    // Start is called before the first frame update
    // void Start(){
    // }

    // Update is called once per frame
    // void Update(){
    // }

    // ---------- API ----------

    // public Vector2 _generate_block_nearest(){

    // }

    public TilemapBlock _generate_1DBlock_by_tile(Vector3Int tile_pos, string type, string[] directions){
        Vector3Int block_offsets = TMapCfg._mapping_mapXY_to_blockXY(tile_pos);
        return _generate_block(block_offsets);
    }
    
    public TilemapBlock _generate_spawn_block(Vector3Int spawn_mapPos, Tilemap tilemap){
        Vector3Int block_offsets = TMapCfg._mapping_worldXY_to_blockXY(spawn_mapPos, tilemap);
        Vector3Int tile_offsets = TMapCfg._mapping_mapXY_to_tileXY_in_block(spawn_mapPos);
        Vector3Int[] spawn_tiles = new Vector3Int[] {tile_offsets};
        // Vector3Int[] spawn_tiles = new Vector3Int[] { tile_offsets , new(tile_offsets.x-1, tile_offsets.y)};
        // if (tile_offsets.x == 0) spawn_tiles[1] = new(tile_offsets.x+1, tile_offsets.y);
        TilemapBlock block = _generate_block(block_offsets, spawn_tiles, new string[]{"horizontal", ""});
        // TilemapBlock block = _generate_1DBlock(block_offsets);
        return block;
    }
    
    public TilemapBlock _generate_block(Vector3Int block_offsets, Vector3Int[] extra_targets=null, string[] direction=null){
        TilemapBlock block = new() {
            offsets = block_offsets,
            isExist = true,
            size = _GCfg.__block_size,
        };
        BAround._set_block(block);

        block = _terrain._random_terrainHier1(block, BAround);
        block = _terrain._random_terrainHier2_random(block, BAround);
        block = BDir._random_direction(block, BAround, _terrain, extra_targets, direction);
        block = fill_1DBlock(block);
        block = generate_2Dblock_transition(block, BAround);
        block = _block_mineral._generate_2DBlock_mineral(block);
        return block;
    }

    TilemapBlock fill_1DBlock(TilemapBlock block){
        // ---------- init ----------
        Vector3Int BSize = _GCfg.__block_size;    // for convenience
        int perlin;
        int[,] map = new int[BSize.x, BSize.y];
        _HeightGenerator height_gen = new(block);
        foreach(Vector3Int pos in block.groundPos){
            height_gen._Add(pos);
        }
        int surface = _terrain.ID2TerrainHier1[block.terrain_ID].surface;
        // ---------- fill map ----------
        for (int x = 0; x < BSize.x; x++){
            perlin = height_gen._get_height(x);
            // fill
            for (int y = 0; y < BSize.y; y++){
                if ((y < perlin && !block.direction_reverse) || (y >= perlin && block.direction_reverse))
                    map[x, y] = surface;
                else
                    map[x, y] = 0;
            }
        }
        block.map = map;
        return block;
    }

    TilemapBlock generate_2Dblock_transition(TilemapBlock block, TilemapBlockAround around_blocks){
        // ---------- init ----------
        Vector3Int BSize = _GCfg.__block_size;    // for convenience
        int perlin;
        _HeightGenerator height_gen = new(block, new(BSize.x, BSize.y / 4)); 
        height_gen._Add(new(0, BSize.y / 8));
        height_gen._Add(new(BSize.x-1, BSize.y / 8));
        // around surface
        int self_surface = _terrain.ID2TerrainHier1[block.terrain_ID].surface;
        int up_surface = around_blocks.up_terrainInfo.surface;
        int down_surface = around_blocks.down_terrainInfo.surface;
        int left_surface = around_blocks.left_terrainInfo.surface;
        int right_surface = around_blocks.right_terrainInfo.surface;

        for (int x = 0; x < BSize.x; x++){
            perlin = height_gen._get_height(x);
            for (int y = 0; y < perlin; y++){
                if (up_surface != 0 && up_surface != self_surface) // up is different, need transition
                    if (block.map[x, BSize.y - y - 1] != 0) block.map[x, BSize.y - y - 1] = up_surface;
                if (down_surface != 0 && down_surface != self_surface) // down is different, need transition
                    if (block.map[x, y] != 0) block.map[x, y] = down_surface;
                if (left_surface != 0 && left_surface != self_surface) // left is different, need transition
                    if (block.map[y, x] != 0) block.map[y, x] = left_surface;
                if (right_surface != 0 && right_surface != self_surface) // right is different, need transition
                    if (block.map[BSize.y - y - 1, x] != 0) block.map[BSize.y - y - 1, x] = right_surface;
            }
        }
        return block;
    }

}

public class _HeightGenerator{
    struct _Tile{
        public int x;       // target x
        public int y;       // target y
        public int perlin;  // perlin result which need to transit to target y
    }
    List<_Tile> _tiles = new();
    TilemapBlock _block;
    Vector3Int _BSize;

    // public _HeightGenerator(TilemapBlock block){
    //     _block = block;
    //     _BSize = block.size;
    // }
    
    public _HeightGenerator(TilemapBlock block, Vector3Int block_size=new()){
        _block = block;
        if (block_size.x == 0 && block_size.y == 0)_BSize = block.size;
        else _BSize = block_size;
    }

    public void _Add(Vector3Int tile_pos){
        // sort
        int insert_index = _tiles.FindIndex(tile => tile.x >= tile_pos.x);
        if (insert_index == -1) insert_index = _tiles.Count;
        // insert
        int perlin = get_perlin(tile_pos.x);
        _Tile tile = new(){x=tile_pos.x, y=tile_pos.y, perlin=perlin};
        _tiles.Insert(insert_index, tile);
    }

    public int _get_height(int x){
        _Tile tile_left = new();
        _Tile tile_right = new();
        // Find pos: (left.x, x, right.x)
        for (int i=1; i<_tiles.Count; i++){
            tile_right = _tiles[i];
            if (tile_right.x >= x ){
                tile_left = _tiles[i-1];
                break;
            }
        }
        int perlin = get_height(tile_left, tile_right, x);
        return perlin;
    }

    int get_perlin(int x){
        // int perlin = Mathf.CeilToInt((_max_h - _min_h) * Mathf.PerlinNoise((x + _base_x)/_scale, 0f)) + _min_h;
        // int perlin = Mathf.CeilToInt(_block_h * Mathf.PerlinNoise((x + _base_x)/_scale, 0f));
        int perlin = Mathf.CeilToInt(_BSize.y * _block._perlin(x));
        return perlin;
    }

    int get_height(_Tile left, _Tile right, int x){
        int perlin = get_perlin(x);
        perlin = limit_target_h(x, perlin, left, right);
        perlin = limit_top_or_bottom(x, perlin, left, right);
        // perlin = _limit_min_h(x, perlin, left, right);
        // perlin = _limit_max_h(x, perlin, left, right);
        return perlin;
    }
    
    // ---------- limit format ----------
    int limit_target_h(int x, int y, _Tile left, _Tile right){
        float diff_a = left.y - left.perlin;
        float diff_b = right.y - right.perlin;
        float distance = right.x - left.x;
        float transition_h = (diff_b - diff_a) / distance * (x - left.x) + diff_a;
        int result = y + Mathf.CeilToInt(transition_h);
        return result;
    }

    int limit_top_or_bottom(int x, int y, _Tile left, _Tile right){
        if (left.y == _BSize.y && right.y == _BSize.y)
            return _BSize.y;
        else if (left.y == 0 && right.y == 0)
            return 0;
        else
            return y;
    }

    // int _limit_min_h(int x, int y, _Tile left, _Tile right){
    //     int min_distance = ((right.x-x) < (x-left.x)) ? right.x-x : x-left.x;
    //     int min_h = Mathf.CeilToInt(_block_h * _bound_h_ratio);
    //     // Above minimum height
    //     if (y >= min_h)
    //         return y;
    //     // limit function for min_h with slope 1, i.e., when min_distance > min_h, directly corrected to min_h
    //     y = (min_distance < min_h) ? min_distance : min_h;
    //     return y;
    // }

    // int _limit_max_h(int x, int y, _Tile left, _Tile right){
    //     int min_distance = ((right.x-x) < (x-left.x)) ? right.x-x : x-left.x;
    //     int min_h = Mathf.CeilToInt(_block_h * _bound_h_ratio);
    //     int max_h = Mathf.CeilToInt(_block_h * (1 - _bound_h_ratio));
    //     // Below maximum height
    //     if (y <= max_h)
    //         return y;
    //     // limit function for max_h with slope 1, i.e., when max_distance > bound_h, directly corrected to max_h
    //     y = (min_distance < min_h) ? _block_h - min_distance : max_h;
    //     return y;
    // }
}
