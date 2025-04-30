using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;
using YamlDotNet.Core.Events;



public class TilemapBlockTerrain: BaseClass{
    public static TilemapBlockTerrainSurface surface = new();
    public static TilemapBlockTerrainMineral mineral = new();
    public TilemapBlock block;

    public TilemapBlockTerrain(TilemapBlock block) {
        this.block = block;
    }

    public async UniTask _generate_terrain(CancellationToken? ct){
        for (int i = 0; i < block.size.x; i++){
            for (int j = 0; j < block.size.y; j++){
                ct?.ThrowIfCancellationRequested();
                Vector3Int map_pos = TilemapAxis._mapping_inBlockPos_to_mapPos(new(i, j), block.offsets);
                TerrainHier1 hier1 = surface._get_hier1(map_pos, _MatSys._terrain._infos.HierBase);
                TilemapTile tile = await TilemapTile._get_force_async(block.layer, map_pos);
                if (tile._check_terrainDone()) continue;
                if (surface._check_underground(map_pos, hier1)){
                    // ----- Base Tile ----- //
                    tile._set_ID_terrain(hier1.base_tile);
                    // ----- Mineral ----- //
                    string mineral_ID = mineral._get_mineral(map_pos, hier1.minerals);
                    if (mineral_ID != null) {
                        tile._set_mineral(mineral_ID);
                    }
                }
                else {
                    tile._set_ID_terrain(GameConfigs._sysCfg.TMap_empty_tile);
                }
            }
        }
    }
}