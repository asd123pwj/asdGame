using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra.Single;
using System;
using Cysharp.Threading.Tasks;
using System.Linq;

public class Region4DrawTilemapBlock{
    public Vector3Int[] positions => pos_tile_kvp.Keys.ToArray();
    public TileBase[] tiles => pos_tile_kvp.Values.ToArray();

    public Dictionary<Vector3Int, TileBase> pos_tile_kvp = new();

    public void _add(Vector3Int pos, TileBase tile){
        pos_tile_kvp.Add(pos, tile);
    }
    
}

public class TilemapBlockDraw: BaseClass{
    public TilemapBlock block;
    public bool isDrawed = false;

    public TilemapBlockDraw(TilemapBlock block){
        this.block = block;
    }

    public async UniTask _draw_block_mine(){
        foreach (TilemapTile tile in block.map.map){
            // TileMatchRule.match(tile.map_pos, block.layer);
            await tile._update_tile();
        }
    }

    // public async UniTask _draw_block(){
    //     Tilemap TMap = block.obj.TMap;
    //     Region4DrawTilemapBlock region_block = _get_draw_region(block);
    //     await _draw_region(TMap, region_block);
        
    //     Dictionary<Vector3Int, Region4DrawTilemapBlock> regions_placeholder = _get_draw_regions_placeholder(block);

    //     foreach (var kvp in regions_placeholder){
    //         // Tilemap TMap_placeholder = _TMapSys._TMapMon._get_blkObj(kvp.Key, block.layer).TMap;
    //         Tilemap TMap_placeholder = (await TilemapBlock._get_force_async(kvp.Key, block.layer)).obj.TMap;
    //         await _draw_region(TMap_placeholder, kvp.Value, isPlaceholder:true);
    //     }

    //     ShadowGenerator._generate_shadow_from_compCollider(
    //         block.obj.obj,
    //         block.obj.compositeCollider
    //     );
    // }
    
    // public async UniTask _draw_tile(TilemapBlock block, Vector2 map_pos){
    //     Tilemap TMap = block.obj.TMap;

    //     Region4DrawTilemapBlock region_block = _get_draw_region(block);
    //     await _draw_region(TMap, region_block);
        
    //     Dictionary<Vector3Int, Region4DrawTilemapBlock> regions_placeholder = _get_draw_regions_placeholder(block);

    //     foreach (var kvp in regions_placeholder){
    //         // Tilemap TMap_placeholder = _TMapSys._TMapMon._get_blkObj(kvp.Key, block.layer).TMap;
    //         Tilemap TMap_placeholder = (await TilemapBlock._get_async(kvp.Key, block.layer)).obj.TMap;
    //         await _draw_region(TMap_placeholder, kvp.Value, isPlaceholder:true);
    //     }

    //     ShadowGenerator._generate_shadow_from_compCollider(
    //         block.obj.obj,
    //         block.obj.compositeCollider
    //     );
    // }

    public Region4DrawTilemapBlock _get_draw_region(TilemapBlock block){
        Vector3Int block_origin_pos = block.offsets * block.size;
        Region4DrawTilemapBlock region = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < block.size.y; y++){
                TileBase tile = null;
                if (block.map._get_tile_foce(x, y) != GameConfigs._sysCfg.TMap_empty_tile) {
                    tile = _MatSys._tile._get_tile(block.map._get_tile_foce(x, y));
                }
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        return region;


    }

    public Dictionary<Vector3Int, Region4DrawTilemapBlock> _get_draw_regions_placeholder(TilemapBlock block){
        // This function aims draw placeholder tiles around the block,
        Vector3Int block_origin_pos = block.offsets * block.size; 
        Vector3Int block_offset;
        Region4DrawTilemapBlock region;
        Dictionary<Vector3Int, Region4DrawTilemapBlock> regions = new();
        Vector3Int neighbor = GameConfigs._sysCfg.TMap_tileNeighborsCheck_max;

        // ----- lower left quarter
        block_offset = block.offsets + new Vector3Int(-1, -1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get_tile_foce(x, y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- upper left quarter
        block_offset = block.offsets + new Vector3Int(-1, 1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get_tile_foce(x, block.size.y - 1 - y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, block.size.y - 1 - y, 0));
                region._add(block_origin_pos + new Vector3Int(x, block.size.y - 1 - y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- lower right quarter
        block_offset = block.offsets + new Vector3Int(1, -1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get_tile_foce(block.size.x - 1 - x, y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, y, 0));
                region._add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- upper right quarter
        block_offset = block.offsets + new Vector3Int(1, 1, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get_tile_foce(block.size.x - 1 - x, block.size.y - 1 - y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, block.size.y - 1 - y, 0));
                region._add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, block.size.y - 1 - y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- left side
        block_offset = block.offsets + new Vector3Int(-1, 0, 0);
        region = new();
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map._get_tile_foce(x, y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);
        // ----- right side
        region = new();
        block_offset = block.offsets + new Vector3Int(1, 0, 0);
        for (int x = 0; x < neighbor.x; x++){
            for (int y = 0; y < block.size.y; y++){
                if (block.map._get_tile_foce(block.size.x - 1 - x, y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(block.size.x - 1 - x, y, 0));
                region._add(block_origin_pos + new Vector3Int(block.size.x - 1 - x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        
        // ----- bottom side
        block_offset = block.offsets + new Vector3Int(0, -1, 0);
        region = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get_tile_foce(x, y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, y, 0));
                region._add(block_origin_pos + new Vector3Int(x, y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        // ----- top side
        block_offset = block.offsets + new Vector3Int(0, 1, 0);
        region = new();
        for (int x = 0; x < block.size.x; x++){
            for (int y = 0; y < neighbor.y; y++){
                if (block.map._get_tile_foce(x, block.size.y - 1 - y) == GameConfigs._sysCfg.TMap_empty_tile) continue;
                TileBase tile = get_placeholder_tile(block, new Vector3Int(x, block.size.y - 1 - y, 0));
                region._add(block_origin_pos + new Vector3Int(x, block.size.y - 1 - y, 0), tile);
            }
        }
        regions.Add(block_offset, region);

        return regions;
    }

    TileBase get_placeholder_tile(TilemapBlock block, Vector3Int position){
        string tile_ID = block.map._get_tile_foce(position.x, position.y);
        TileBase tile = _MatSys._tile._get_tile(tile_ID);
        return tile;
    }


    public async UniTask _draw_region(Tilemap tilemap, Region4DrawTilemapBlock region, bool isPlaceholder=false){
        // System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        // stopwatch.Start();


        Color transparent = new(1, 1, 1, 0);
        int tile_per_group = Mathf.Min(GameConfigs._sysCfg.TMap_tiles_per_loading, region.tiles.Count());
        Vector3Int[] positions = region.positions;
        TileBase[] tiles = region.tiles;
        for (int i = 0; i < region.tiles.Count(); i += tile_per_group) {
            if (i + tile_per_group > region.tiles.Count()) 
                tile_per_group = region.tiles.Count() - i;
            Vector3Int[] positions_segment = new ArraySegment<Vector3Int>(positions, i, tile_per_group).ToArray();
            TileBase[] tiles_segment = new ArraySegment<TileBase>(tiles, i, tile_per_group).ToArray();
            
            // ----- Draw tile ----- //
            tilemap.SetTiles(positions_segment, tiles_segment);

            // ----- Set Placeholder ----- //
            if (isPlaceholder){
                foreach (var tile_pos in positions_segment){
                    tilemap.SetColor(tile_pos, transparent);
                }
            }

            await UniTask.Delay(GameConfigs._sysCfg.TMap_interval_per_loading);
        }

        // stopwatch.Stop();
        // Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds);
    }





}