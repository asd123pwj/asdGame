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

    public void _generate_terrain(CancellationToken? ct){
        // if (ct.Value.IsCancellationRequested) return;
        for (int i = 0; i < block.size.x; i++){
            for (int j = 0; j < block.size.y; j++){
                // if (ct.Value.IsCancellationRequested) return;
                ct?.ThrowIfCancellationRequested();
                Vector3Int map_pos = TilemapAxis._mapping_inBlockPos_to_mapPos(new(i, j), block.offsets);
                TerrainHier1 hier1 = surface._get_hier1(map_pos, _MatSys._terrain._infos.HierBase);
                if (surface._check_underground(map_pos, hier1)){
                    // ----- Base Tile ----- //
                    block.map._set_tile(i, j, hier1.base_tile);
                    // ----- Mineral ----- //
                    string mineral_ID = mineral._get_mineral(map_pos, hier1.minerals);
                    if (mineral_ID != null) block.map._get_force(i, j)._set_mineral(mineral_ID);
                }
                else {
                    block.map._set_tile(i, j, GameConfigs._sysCfg.TMap_empty_tile);
                }
            }
        }
    }
}