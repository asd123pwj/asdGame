using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterTexture : BaseClass{
    public async UniTaskVoid _init_mesh(WaterBase water){
        await UniTask.Delay(50);
        // string mat_name = "Liquid_Water";
        string sprMat_name = "l1";
        string mesh_name = "Size1.5x1.5_Grid6x6_AxisXY";
        water.meshFilter.mesh = _sys._MatSys._mesh._get_mesh(mesh_name);
        water.mesh = water.meshFilter.mesh;
        // meshRenderer.material = _sys._MatSys._mat._get_mat(mat_name);
        // List<string> items = new List<string>() {"__Full", "__Front", "__Side", "__Up"};
        // int randomIndex = Random.Range(0, items.Count);
        water.meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, "__Full");
        // meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, items[randomIndex]);
        water.meshCollider.sharedMesh = water.mesh;
        water._self.SetActive(false);
        water._mesh_init_done = true;
    }

    // public void _update_mesh_4x4(WaterBase water){
    //     // await UniTask.Delay(50);
    //     // string mat_name = "Liquid_Water";
    //     string sprMat_name = "l1";
    //     string mesh_name = "Size1x1_Grid4x4_AxisXY";
    //     water.meshFilter.mesh = _sys._MatSys._mesh._get_mesh(mesh_name);
    //     water.mesh = water.meshFilter.mesh;
    //     // meshRenderer.material = _sys._MatSys._mat._get_mat(mat_name);
    //     List<string> items = new List<string>() {"__Full", "__Front", "__Side", "__Up"};
    //     int randomIndex = Random.Range(0, items.Count);
    //     water.meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, "__Front");
    //     // meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, items[randomIndex]);
    //     water.meshCollider.sharedMesh = water.mesh;
    //     // water._mesh_init_done = true;
    // }

    // public void _update_mesh_6x6(WaterBase water, string name){
    //     // await UniTask.Delay(50);
    //     // string mat_name = "Liquid_Water";
    //     string sprMat_name = "l1";
    //     string mesh_name = "Size1.5x1.5_Grid6x6_AxisXY";
    //     water.meshFilter.mesh = _sys._MatSys._mesh._get_mesh(mesh_name);
    //     water.mesh = water.meshFilter.mesh;
    //     // meshRenderer.material = _sys._MatSys._mat._get_mat(mat_name);
    //     // List<string> items = new List<string>() {"__Full", "__Front", "__Side", "__Up"};
    //     // int randomIndex = Random.Range(0, items.Count);
    //     water.meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, name);
    //     // meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, items[randomIndex]);
    //     water.meshCollider.sharedMesh = water.mesh;
    //     // water._mesh_init_done = true;
    // }

}
