using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapBlockGenerator: BaseClass{
    TilemapAxis TMapCfg { get => _TMapSys._TMapAxis; }
    // GameConfigs _GCfg;
    // DirectionsConfig DirCfg = new();
    // TilemapBlockAround BAround;
    TilemapBlockDirection BDir;
    public TilemapTerrain _terrain;
    TilemapBlockMineral _block_mineral;

    public TilemapBlockGenerator(){
        // _tilemap_base = tilemap_base;
        // _GCfg = game_configs;
        _terrain = new();
        // BAround = new(_terrain);
        BDir = new();
        _block_mineral = new(_terrain);
        // _block_transition = new(_tilemap_base, _game_configs, _terrain);
    }


    // public TilemapBlock _generate_1DBlock_by_tile(Vector3Int tile_pos, string type, string[] directions){
    //     Vector3Int block_offsets = TMapCfg._mapping_mapXY_to_blockXY(tile_pos);
    //     return _generate_block(block_offsets);
    // }

    // public TilemapBlock _generate_spawn_block(Vector3Int spawn_mapPos, Tilemap tilemap){
    //     Vector3Int block_offsets = TMapCfg._mapping_worldXY_to_blockXY(spawn_mapPos, tilemap);
    //     Vector3Int tile_offsets = TMapCfg._mapping_mapXY_to_tileXY_in_block(spawn_mapPos);
    //     Vector3Int[] spawn_tiles = new Vector3Int[] {tile_offsets};
    //     // Vector3Int[] spawn_tiles = new Vector3Int[] { tile_offsets , new(tile_offsets.x-1, tile_offsets.y)};
    //     // if (tile_offsets.x == 0) spawn_tiles[1] = new(tile_offsets.x+1, tile_offsets.y);
    //     TilemapBlock block = _generate_block(block_offsets, spawn_tiles, new string[]{"horizontal", ""});
    //     // TilemapBlock block = _generate_1DBlock(block_offsets);
    //     return block;
    // }

    public TilemapBlock _generate_block(Vector3Int block_offsets,
                                        // int initStage_begin=0, 
                                        int initStage_end=99, 
                                        Vector3Int[] extra_targets=null, 
                                        string[] direction=null,
                                        string layer_type = "L1_Middle"){
        TilemapBlock block = 
            _TMapSys._TMapMon._check_block_load(block_offsets, layer_type)
            ? _TMapSys._TMapMon._get_block(block_offsets, layer_type)
            : new(){
              offsets = block_offsets,
              isExist = true,
              layer = layer_type
              };
        TilemapBlockAround BAround = new(block);
        int initStage_begin = System.Math.Max(block.initStage, 0);
        initStage_end = System.Math.Max(block.initStage, initStage_end);
        bool need_update = false;

        if (block.offsets.x == 2 && block.offsets.y == -9) {
            int a = 1;
        }
        if (initStage_begin <= 1 && initStage_end >= 1) {
            block = _terrain._random_terrainHier1(block, BAround);
            need_update = true;
        }
        if (initStage_begin <= 2 && initStage_end >= 2) {
            block = _terrain._random_terrainHier2(block, BAround);
            need_update = true;
        }
        if (initStage_begin <= 3 && initStage_end >= 3) {
            block = BDir._random_direction(block, BAround, _terrain, extra_targets, direction);
            need_update = true;
        }
        if (initStage_begin <= 4 && initStage_end >= 4) {
            block = fill_1DBlock(block);
            need_update = true;
        }
        if (initStage_begin <= 5 && initStage_end >= 5) {
            block = generate_errorBlock_transition(block, BAround);
            need_update = true;
        }
        if (initStage_begin <= 6 && initStage_end >= 6) {
            block = generate_2Dblock_transition(block, BAround);
            need_update = true;
        }
        if (initStage_begin <= 7 && initStage_end >= 7) {
            block = _block_mineral._generate_2DBlock_mineral(block);
            need_update = true;
        }

        if (need_update) {
            block.initStage = initStage_end;
            _TMapSys._TMapMon._update_block(block);
        }
        return block;
    }

    TilemapBlock fill_1DBlock(TilemapBlock block){
        // ---------- init ----------
        Vector3Int BSize = _GCfg._sysCfg.TMap_tiles_per_block;    // for convenience
        int perlin;
        string[,] map = new string[BSize.x, BSize.y];
        HeightGenerator height_gen = new(block);
        foreach(Vector3Int pos in block.groundPos){
            height_gen._Add(pos);
        }
        string surface = _terrain.ID2TerrainHier1[block.terrain_ID].surface;
        // ---------- fill map ----------
        for (int x = 0; x < BSize.x; x++){
            perlin = height_gen._get_height(x);
            // fill
            for (int y = 0; y < BSize.y; y++){
                if ((y < perlin && !block.direction_reverse) || (y >= perlin && block.direction_reverse))
                    map[x, y] = surface;
                else
                    map[x, y] = _GCfg._empty_tile;
            }
        }
        block.map = map;
        return block;
    }

    TilemapBlock generate_errorBlock_transition(TilemapBlock block, TilemapBlockAround around_blocks){
        if (block.direction[0] != "error"){
            return block;
        }
        // ---------- init ----------
        Vector3Int BSize = _GCfg._sysCfg.TMap_tiles_per_block;    // for convenience
        string self_surface = _terrain.ID2TerrainHier1[block.terrain_ID].surface;

        int ground_start = -1, ground_end = -2;
        // ----- Generate Buttom ----- //
        while (around_blocks.down.isExist){
            for (int i = 0; i < BSize.x; i++){
                if (around_blocks.down.map[i, BSize.y - 1] != _GCfg._empty_tile){
                    ground_start = i; 
                    break;
                }
            }
            if (ground_start == -1) break;
            for (int i = ground_start; i < BSize.x; i++){
                if (around_blocks.down.map[i, BSize.y - 1] == _GCfg._empty_tile){
                    ground_end = i;
                    break;
                }
            }
            if (ground_end == -2) ground_end = BSize.x;
            for (int i = ground_start; i < ground_end; i++){
                float y = block._perlin(i, 0, scale:4) * BSize.y / 4;
                for (int j = 0; j < y; j++){
                    block.map[i, j] = self_surface;
                }
            }
            break;
        }
        // ----- Generate Top ----- //
        ground_start = -1; ground_end = -2;
        while (around_blocks.up.isExist){
            for (int i = 0; i < BSize.x; i++){
                if (around_blocks.up.map[i, 0] != _GCfg._empty_tile){
                    ground_start = i; 
                    break;
                }
            }
            if (ground_start == -1) break;
            for (int i = ground_start; i < BSize.x; i++){
                if (around_blocks.up.map[i, 0] == _GCfg._empty_tile){
                    ground_end = i;
                    break;
                }
            }
            if (ground_end == -2) ground_end = BSize.x;
            for (int i = ground_start; i < ground_end; i++){
                float y = block._perlin(i, BSize.y, scale:4) * BSize.y / 4;
                for (int j = 0; j < y; j++){
                    block.map[i, BSize.y - 1 - j] = self_surface;
                }
            }
            break;
        }
        // ----- Generate Left ----- //
        ground_start = -1; ground_end = -2;
        while (around_blocks.left.isExist){
            for (int j = 0; j < BSize.y; j++){
                if (around_blocks.left.map[BSize.x - 1, j] != _GCfg._empty_tile){
                    ground_start = j; 
                    break;
                }
            }
            if (ground_start == -1) break;
            for (int j = ground_start; j < BSize.y; j++){
                if (around_blocks.left.map[BSize.x - 1, j] == _GCfg._empty_tile){
                    ground_end = j;
                    break;
                }
            }
            if (ground_end == -2) ground_end = BSize.y;
            for (int j = ground_start; j < ground_end; j++){
                float x = block._perlin(0, j, scale:4) * BSize.x / 4;
                for (int i = 0; i < x; i++){
                    block.map[i, j] = self_surface;
                }
            }
            break;
        }
        // ----- Generate Right ----- //
        ground_start = -1; ground_end = -2;
        while (around_blocks.right.isExist){
            for (int j = 0; j < BSize.y; j++){
                if (around_blocks.right.map[0, j] != _GCfg._empty_tile){
                    ground_start = j; 
                    break;
                }
            }
            if (ground_start == -1) break;
            for (int j = ground_start; j < BSize.y; j++){
                if (around_blocks.right.map[0, j] == _GCfg._empty_tile){
                    ground_end = j;
                    break;
                }
            }
            if (ground_end == -2) ground_end = BSize.y;
            for (int j = ground_start; j < ground_end; j++){
                float x = block._perlin(BSize.x, j, scale:4) * BSize.x / 4;
                for (int i = 0; i < x; i++){
                    block.map[BSize.x - 1 - i, j] = self_surface;
                }
            }
            break;
        }

        return block;
    }

    TilemapBlock generate_2Dblock_transition(TilemapBlock block, TilemapBlockAround around_blocks){
        // ---------- init ----------
        Vector3Int BSize = _GCfg._sysCfg.TMap_tiles_per_block;    // for convenience
        int perlin;
        HeightGenerator height_gen = new(block, new(BSize.x, BSize.y / 4)); 
        height_gen._Add(new(0, BSize.y / 8));
        height_gen._Add(new(BSize.x-1, BSize.y / 8));
        // around surface
        string self_surface = _terrain.ID2TerrainHier1[block.terrain_ID].surface;
        string up_surface = around_blocks.up_terrainInfo.surface;
        string down_surface = around_blocks.down_terrainInfo.surface;
        string left_surface = around_blocks.left_terrainInfo.surface;
        string right_surface = around_blocks.right_terrainInfo.surface;

        for (int x = 0; x < BSize.x; x++){
            perlin = height_gen._get_height(x);
            for (int y = 0; y < perlin; y++){
                if (up_surface != null && up_surface != self_surface) // up is different, need transition
                    if (block.map[x, BSize.y - y - 1] != _GCfg._empty_tile) block.map[x, BSize.y - y - 1] = up_surface;
                if (down_surface != null && down_surface != self_surface) // down is different, need transition
                    if (block.map[x, y] != _GCfg._empty_tile) block.map[x, y] = down_surface;
                if (left_surface != null && left_surface != self_surface) // left is different, need transition
                    if (block.map[y, x] != _GCfg._empty_tile) block.map[y, x] = left_surface;
                if (right_surface != null && right_surface != self_surface) // right is different, need transition
                    if (block.map[BSize.y - y - 1, x] != _GCfg._empty_tile) block.map[BSize.y - y - 1, x] = right_surface;
            }
        }
        return block;
    }

}
