using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public class TilemapBlockGameObject: BaseClass{
    public GameObject obj;
    public TilemapBlockStatus TMap_status;
    public Tilemap TMap;
    // public TilemapRenderer TMap_renderer;
    public TilemapCollider2D TMap_collider;
    public Rigidbody2D rb;
    public CompositeCollider2D compositeCollider;
    public GameObject tile_container;
    public GameObject P3D_container;
    public GameObject Decoration_container;
    public TilemapBlock _me;


    public TilemapBlockGameObject(TilemapBlock block){
        _me = block;
        obj = new GameObject();
        obj.transform.SetParent(_TMapSys._TMapMon._TMap_containers[_me.layer.ToString()]);
        // obj.obj.transform.SetParent();

        
        obj.name = _me.offsets.x + "_" + _me.offsets.y;
        // obj.obj.layer = LayerMask.NameToLayer(layer_type);

        // ----- Container ----- //
        tile_container = new GameObject("Tiles" + obj.name);
        // obj.tile_container.transform.SetParent(obj.obj.transform);
        tile_container.transform.SetParent(_TMapSys._TMapMon._TMap_containers[new LayerType(0).ToString()]);
        
        P3D_container = new GameObject("P3Ds" + obj.name);
        // obj.P3D_container.transform.SetParent(obj.obj.transform);
        P3D_container.transform.SetParent(_TMapSys._TMapMon._TMap_containers[new LayerType(0).ToString()]);
        
        Decoration_container = new GameObject("Decorations" + obj.name);
        // obj.Decoration_container.transform.SetParent(obj.obj.transform);
        Decoration_container.transform.SetParent(_TMapSys._TMapMon._TMap_containers[new LayerType(0).ToString()]);

        // ----- Tilemap ----- //
        TMap = obj.AddComponent<Tilemap>();
        TMap.tileAnchor = Vector3Int.zero;

        // ----- TilemapRenderer ----- //
        // obj.TMap_renderer = obj.obj.AddComponent<TilemapRenderer>();
        // obj.TMap_renderer.material = _MatSys._mat._get_mat("TransparentSprite");
        // obj.TMap_renderer.sortingLayerID = layer_type.sortingLayerID;
        // obj.TMap_renderer.sortingOrder = layer_type.sortingOrder;
        
        // obj.TMap_renderer.renderingLayerMask = 0;


        TMap_status = obj.AddComponent<TilemapBlockStatus>();
        TMap_status.sortingOrder = _me.layer.sortingOrder;
        // obj.TMap_renderer.material = _MatSys._mat._get_mat("TransparentSprite");
        // obj.TMap_renderer.sortingLayerID = layer_type.sortingLayerID;
        // obj.TMap_renderer.sortingOrder = layer_type.sortingOrder;


        // --- !!! Necessary for Pseudo3D: 
        // --- TilemapRenderer.Mode.Individual: make tile overlap tile, while Mode.Chunk make tile overlap tile only same type
        // --- URP render data, "Transparency Sort Axis" with "x=-1, y=-1, z=0": make top overlap bottom, make right overlap left
        // --- Now, I dont need to draw tilemap in different overlap, "7 sprite for 1 tile" is PAST, "1 sprite for 1 tile" is NOW.
        // obj.TMap_renderer.mode = TilemapRenderer.Mode.Individual;

        // ----- TilemapCollider2D ----- //
        TMap_collider = obj.AddComponent<TilemapCollider2D>();
        TMap_collider.usedByComposite = true;

        // ----- CompositeCollider2D ----- //
        compositeCollider = obj.AddComponent<CompositeCollider2D>();

        // ----- Rigidbody2D ----- //
        // --- When CompositeCollider2D add, Rigidbody2D will be added automatically by Unity.
        // obj.TMap_rb = obj.TMap_obj.AddComponent<Rigidbody2D>();

        rb = obj.GetComponent<Rigidbody2D>();
        rb.bodyType = RigidbodyType2D.Static;
        rb.sharedMaterial = _MatSys._phyMat._get_phyMat("Default");
    }
}

// public class TilemapBlockGameObjectGenerator: BaseClass{
//     public TilemapBlockGameObjectGenerator(){
//     }


//     public TilemapBlockGameObject _init_tilemap_gameObject(Vector3Int block_offsets, LayerType layer_type=null){
//         TilemapBlockGameObject obj = new();
//         layer_type ??= new LayerType();
//         // ----- GameObject ----- //
//         obj.obj = new GameObject();
//         obj.obj.transform.SetParent(_TMapSys._TMapMon._TMap_containers[layer_type.ToString()]);
//         // obj.obj.transform.SetParent();

        
//         obj.obj.name = block_offsets.x + "_" + block_offsets.y;
//         // obj.obj.layer = LayerMask.NameToLayer(layer_type);

//         // ----- Container ----- //
//         obj.tile_container = new GameObject("Tiles" + obj.obj.name);
//         // obj.tile_container.transform.SetParent(obj.obj.transform);
//         obj.tile_container.transform.SetParent(_TMapSys._TMapMon._TMap_containers[new LayerType(0).ToString()]);
        
//         obj.P3D_container = new GameObject("P3Ds" + obj.obj.name);
//         // obj.P3D_container.transform.SetParent(obj.obj.transform);
//         obj.P3D_container.transform.SetParent(_TMapSys._TMapMon._TMap_containers[new LayerType(0).ToString()]);
        
//         obj.Decoration_container = new GameObject("Decorations" + obj.obj.name);
//         // obj.Decoration_container.transform.SetParent(obj.obj.transform);
//         obj.Decoration_container.transform.SetParent(_TMapSys._TMapMon._TMap_containers[new LayerType(0).ToString()]);

//         // ----- Tilemap ----- //
//         obj.TMap = obj.obj.AddComponent<Tilemap>();
//         obj.TMap.tileAnchor = Vector3Int.zero;

//         // ----- TilemapRenderer ----- //
//         // obj.TMap_renderer = obj.obj.AddComponent<TilemapRenderer>();
//         // obj.TMap_renderer.material = _MatSys._mat._get_mat("TransparentSprite");
//         // obj.TMap_renderer.sortingLayerID = layer_type.sortingLayerID;
//         // obj.TMap_renderer.sortingOrder = layer_type.sortingOrder;
        
//         // obj.TMap_renderer.renderingLayerMask = 0;


//         obj.TMap_status = obj.obj.AddComponent<TilemapBlockStatus>();
//         obj.TMap_status.sortingOrder = layer_type.sortingOrder;
//         // obj.TMap_renderer.material = _MatSys._mat._get_mat("TransparentSprite");
//         // obj.TMap_renderer.sortingLayerID = layer_type.sortingLayerID;
//         // obj.TMap_renderer.sortingOrder = layer_type.sortingOrder;


//         // --- !!! Necessary for Pseudo3D: 
//         // --- TilemapRenderer.Mode.Individual: make tile overlap tile, while Mode.Chunk make tile overlap tile only same type
//         // --- URP render data, "Transparency Sort Axis" with "x=-1, y=-1, z=0": make top overlap bottom, make right overlap left
//         // --- Now, I dont need to draw tilemap in different overlap, "7 sprite for 1 tile" is PAST, "1 sprite for 1 tile" is NOW.
//         // obj.TMap_renderer.mode = TilemapRenderer.Mode.Individual;

//         // ----- TilemapCollider2D ----- //
//         obj.TMap_collider = obj.obj.AddComponent<TilemapCollider2D>();
//         obj.TMap_collider.usedByComposite = true;

//         // ----- CompositeCollider2D ----- //
//         obj.compositeCollider = obj.obj.AddComponent<CompositeCollider2D>();

//         // ----- Rigidbody2D ----- //
//         // --- When CompositeCollider2D add, Rigidbody2D will be added automatically by Unity.
//         // obj.TMap_rb = obj.TMap_obj.AddComponent<Rigidbody2D>();

//         obj.rb = obj.obj.GetComponent<Rigidbody2D>();
//         obj.rb.bodyType = RigidbodyType2D.Static;
//         obj.rb.sharedMaterial = _MatSys._phyMat._get_phyMat("Default");

//         return obj;
//     }
    
// }
