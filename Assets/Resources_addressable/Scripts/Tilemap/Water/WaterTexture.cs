using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterTexture : BaseClass{
    public async UniTaskVoid _init_mesh(WaterBase water){
        await UniTask.Delay(10);
        // string mat_name = "Liquid_Water";
        string sprMat_name = "l1";
        string mesh_name = "Size1.5x1.5_Grid6x6_AxisXY";
        water.meshFilter.mesh = _sys._MatSys._mesh._get_mesh(mesh_name);
        water.mesh = water.meshFilter.mesh;
        water.meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, "__Full");
        water.meshCollider.sharedMesh = water.mesh;
        water._self.SetActive(false);
        water._mesh_init_done = true;
    }

}
