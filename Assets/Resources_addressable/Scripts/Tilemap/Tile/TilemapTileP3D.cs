// using System.Threading;
// using Cysharp.Threading.Tasks;
// using UnityEngine;


// public class TilemapTileP3D : BaseClass{
//     Vector3Int map_pos => tile.map_pos;
//     TilemapTile tile;
//     Transform container;
//     LayerType P3D_layer;
//     // ---------- Status ---------- //
//     public GameObject _self;
//     public SpriteRenderer _renderer;
//     public string tile_ID => tile.tile_ID;
//     public string tile_subID => tile.tile_subID;

//     public TilemapTileP3D(TilemapTile tile){
//         this.tile = tile;
//         P3D_layer = new(tile.block.layer, MapLayerType.MiddleP3D);
//         _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, P3D_layer);
//         _renderer.sortingLayerID = P3D_layer.sortingLayerID;
//         _renderer.sortingOrder = P3D_layer.sortingOrder;
//         this.container = tile.block.obj.P3D_container.transform;
//         _self.transform.SetParent(container);
//     }

//     public override void _init(){
//         init_gameObject();
//     }

//     // public async UniTask _update_sprite(CancellationToken? ct){
//     //     ct?.ThrowIfCancellationRequested();
//     public void _update_sprite(){
//         if (tile_subID == null) return;
//         _renderer.sprite = _MatSys._tile._get_P3D(tile_ID, tile_subID);
//         string mat_ID = "TransparentSprite";
//         _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
//     }

//     void init_gameObject(){
//         _self = new("P3D");
//         _self.isStatic = true;
//         _renderer = _self.AddComponent<SpriteRenderer>();
//     }
    
// }
