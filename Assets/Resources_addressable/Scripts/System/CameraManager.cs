using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;


public class CameraManager{
    // ---------- System Tools ----------
    SystemManager sys;
    // ---------- Status ----------
    readonly float tile_unitSize = 1.0f;
    int rowTiles_in_camera_max = 128;
    int rowTiles_in_camera_min = 16;
    int rowTiles_in_camera = 32;
    float camera_width { get => tile_unitSize * rowTiles_in_camera; }
    float orthographic_size { get => camera_width / (2f * Camera.main.aspect); }

    public CameraManager(SystemManager sys){
        this.sys = sys;
    }

    public void init(){
        
    }

    public void zoomIn(){
        if (rowTiles_in_camera < rowTiles_in_camera_max){
            rowTiles_in_camera += 2;
            Camera.main.orthographicSize = orthographic_size;
        }
    }

    public void zoomOut(){
        if (rowTiles_in_camera > rowTiles_in_camera_min){
            rowTiles_in_camera -= 2;
            Camera.main.orthographicSize = orthographic_size;
        }
    }

}