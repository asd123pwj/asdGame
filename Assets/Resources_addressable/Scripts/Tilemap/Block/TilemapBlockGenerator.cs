using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapBlockGenerator: BaseClass{
    TilemapConfig TMapCfg { get => _TMapSys._TMapCfg; }
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
                                        TilemapBlock block = null,
                                        int initStage_begin=0, 
                                        int initStage_end=99, 
                                        Vector3Int[] extra_targets=null, 
                                        string[] direction=null){
        block ??= new(){
            offsets = block_offsets,
            isExist = true,
        };
        TilemapBlockAround BAround = new(block);

        if (initStage_begin <= 0 && initStage_end >= 0) block = _terrain._random_terrainHier1(block, BAround);
        if (initStage_begin <= 1 && initStage_end >= 1) block = _terrain._random_terrainHier2_random(block, BAround);
        if (initStage_begin <= 2 && initStage_end >= 2) block = BDir._random_direction(block, BAround, _terrain, extra_targets, direction);
        if (initStage_begin <= 3 && initStage_end >= 3) block = fill_1DBlock(block);
        if (initStage_begin <= 4 && initStage_end >= 4) block = generate_2Dblock_transition(block, BAround);
        if (initStage_begin <= 5 && initStage_end >= 5) block = _block_mineral._generate_2DBlock_mineral(block);
        block.initStage = initStage_end;
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
