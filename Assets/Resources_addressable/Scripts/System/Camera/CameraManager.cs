using System.Collections.Generic;
using UnityEngine;
using Cinemachine;
using MathNet.Numerics.LinearAlgebra;


public class CameraManager: BaseClass{
    // ---------- System Tools ----------
    // ---------- Status ----------
    readonly float tile_unitSize = 1f;
    // float rowTiles_in_camera_max = 128;
    // float rowTiles_in_camera_min = 4;
    float rowTiles_in_camera;
    float camera_width { get => tile_unitSize * rowTiles_in_camera; }
    float orthographic_size { get => camera_width / (2f * Camera.main.aspect); }
    Camera cam_main;
    CinemachineVirtualCamera cam_player;
    CameraCommandHandler handler;

    public CameraManager(){
    }

    public override bool _check_allow_init(){
        if (!_sys._initDone) return false;
        if (!_InputSys._initDone) return false;
        return true;
    }

    public override void _init(){
        // Get camera
        cam_main = Camera.main;
        cam_player = _sys._searchInit<CinemachineVirtualCamera>("Camera", "Player Camera");
        // Set default camera
        rowTiles_in_camera = GameConfigs._sysCfg.CAM_rowTiles_in_playerCamera_default;
        cam_player.m_Lens.OrthographicSize = orthographic_size;
        handler = new CameraCommandHandler();
    }

    public bool _zoom(bool isZoomIn){
        if (isZoomIn && rowTiles_in_camera < GameConfigs._sysCfg.CAM_rowTiles_in_playerCamera_max){
            rowTiles_in_camera += 1f;
            cam_player.m_Lens.OrthographicSize = orthographic_size;
        }
        else if (!isZoomIn && rowTiles_in_camera > GameConfigs._sysCfg.CAM_rowTiles_in_playerCamera_min){
            rowTiles_in_camera -= 1f;
            cam_player.m_Lens.OrthographicSize = orthographic_size;
        }
        return true;
    }

    public void _set_camera_follow(Transform target){
        cam_player.Follow = target;
    }

}