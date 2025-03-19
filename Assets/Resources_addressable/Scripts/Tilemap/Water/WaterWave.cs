using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterWave : BaseClass{
    public float waveSpeed = 1f;
    public float waveHeight = 20f;
    public float waveFrequency = 1f;
    public int wave_row_start = 2;

    public static Vector3[] vertices_ori_4x4 = new Vector3[25];

    public WaterWave(){
        for (int x = 0; x < 5; x++){
            for (int y = 0; y < 5; y++){
                vertices_ori_4x4[ixy.i(x, y, 5)] = new() { x = x / (5 - 1), y = y / (5 - 1) };
            }
        }
    }
    
    public void _wave(WaterBase water){
        if (water._amount == 0) {
            water._self.SetActive(false);
            return;
        }
        water._self.SetActive(true);
        if (water._isToppest){
            _scale_to_amount(water);
            water._isToppestBefore = true;
            return;
        }
        if (water._isToppestBefore){        // If: Only "toppest before" should recover, cause other have recovered, no need to recover again
            _recover(water);
            water._isToppestBefore = false;
        }
    }

    public void _recover(WaterBase water){
        water.mesh.vertices = vertices_ori_4x4;
        water.mesh.RecalculateNormals();
    }
    
    public void _scale_to_amount(WaterBase water){
        float scale = (float)water._amount / _sys._GCfg._sysCfg.water_full_amount;
        Vector3[] vertices_new = new Vector3[water.mesh.vertices.Length];

        int row = 5;
        int col = 5;
        for (int x = 0; x < row; x++){
            for (int y = 0; y < col; y++){
                int i = ixy.i(x, y, col);
                Vector3 vertex = water.mesh.vertices[i];
                vertex.x = x / (row - 1); // normalize
                vertex.y = y / (col - 1) * scale;
                vertices_new[i] = vertex;

            }
        }
        water.mesh.vertices = vertices_new;
        water.mesh.RecalculateNormals();
    }
}
