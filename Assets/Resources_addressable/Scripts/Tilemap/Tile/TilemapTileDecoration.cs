// using System.Threading;
// using Cysharp.Threading.Tasks;
// using UnityEngine;


// public class TilemapTileDecoration : BaseClass{
//     Vector3Int map_pos => tile.map_pos;
//     Transform container;
//     LayerType layer_decoration;
//     TilemapTile tile;
//     // ---------- Status ---------- //
//     public GameObject _self;
//     public SpriteRenderer _renderer;
//     string sprite_ID => tile.mineral_ID;
//     string subID => tile.tile_subID;

//     public TilemapTileDecoration(TilemapTile tile){
//         this.tile = tile;
//         layer_decoration = new(tile.block.layer, MapLayerType.MiddleDecoration);
//         _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, layer_decoration);
//         _renderer.sortingLayerID = layer_decoration.sortingLayerID;
//         _renderer.sortingOrder = layer_decoration.sortingOrder;
//         _renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");
//         this.container = tile.block.obj.Decoration_container.transform;
//         _self.transform.SetParent(container);
//     }

//     public override void _init(){
//         init_gameObject();
//     }
//     // public async UniTask _update_sprite(CancellationToken? ct){
//     //     ct?.ThrowIfCancellationRequested();
//     public void _update_sprite(){
//         if (tile.tile_subID == null) return;
//         Sprite sprite = _MatSys._spr._get_sprite(sprite_ID, subID);
//         _renderer.sprite = sprite;

//     }

//     void init_gameObject(){
//         _self = new("BlockDecoration");
//         _self.isStatic = true;
//         _renderer = _self.AddComponent<SpriteRenderer>();
//     }
    
// }
