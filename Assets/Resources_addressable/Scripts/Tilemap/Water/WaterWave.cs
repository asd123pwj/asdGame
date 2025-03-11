using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterWave : BaseClass{
    public float waveSpeed = 1f;
    public float waveHeight = 20f;
    public float waveFrequency = 1f;
    public int wave_row_start = 2;
    
    public void _wave(WaterBase water){
        if (water._amount > 0){
            water._self.SetActive(true);
            _scale_to_amount(water);
        }
        else
            water._self.SetActive(false);
    }
    
    public void _scale_to_amount(WaterBase water){
        if (water._amount == 0) return;
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
