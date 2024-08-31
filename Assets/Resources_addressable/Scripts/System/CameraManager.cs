using System.Collections.Generic;
using UnityEngine;
using Cinemachine;
using MathNet.Numerics.LinearAlgebra;


public class CameraManager: BaseClass{
    // ---------- System Tools ----------
    // ---------- Status ----------
    readonly float tile_unitSize = 1f;
    float rowTiles_in_camera_max = 128;
    float rowTiles_in_camera_min = 4;
    float rowTiles_in_camera = 32;
    float camera_width { get => tile_unitSize * rowTiles_in_camera; }
    float orthographic_size { get => camera_width / (2f * Camera.main.aspect); }
    Camera cam_main;
    CinemachineVirtualCamera cam_player;

    public CameraManager(){
    }

    public override bool _check_loaded(){
        if (!_sys._initDone) return false;
        if (!_InputSys._initDone) return false;
        return true;
    }

    public override void _init(){
        _InputSys._register_action("Zoom In", zoomIn, "isDown");
        _InputSys._register_action("Zoom Out", zoomOut, "isDown");
        cam_main = Camera.main;
        cam_player = _sys._searchInit<CinemachineVirtualCamera>("Camera", "Player Camera");

    }

    public bool zoomIn(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (rowTiles_in_camera < rowTiles_in_camera_max){
            rowTiles_in_camera += 0.5f;
            cam_player.m_Lens.OrthographicSize = orthographic_size;
        }
        return true;
    }

    public bool zoomOut(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        if (rowTiles_in_camera > rowTiles_in_camera_min){
            rowTiles_in_camera -= 0.5f;
            cam_player.m_Lens.OrthographicSize = orthographic_size;
        }
        return true;
    }

}