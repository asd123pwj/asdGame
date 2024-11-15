using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapTerrainSurface: BaseClass{
    // public int surface_max = 100;
    // public float surface_frequency = 0.25f;

    // public int mountain_max = 200;
    // public float mountain_frequency = 1f;

    // public float hier1_frequency = 1f;

    // public int vertical_edge_noise_scale = 100;


    // ---------- Horizontal Edge ---------- //
    // public int _get_h(Vector3Int map_pos, NoiseCfg surface){
    //     _GCfg._noise._set_fractal_type(surface.fractal);
    //     _GCfg._noise._set_noise(surface.noise);
    //     float h_ratio = _GCfg._noise._get(map_pos.x, surface.f);
    //     // float h_ratio = _GCfg._noise._perlin(map_pos.x, frequency);
    //     int h = Mathf.FloorToInt((surface.h_max - surface.h_min) * h_ratio) + surface.h_min;
    //     // int h;
    //     // if ((h_ratio > 0 && type == "-") || (h_ratio < 0 && type == "+")){
    //     //     h = origin;
    //     // }
    //     // else 
    //     //     h = Mathf.FloorToInt(scale * h_ratio) + origin;
    //     return h;
    // }


    public bool _check_underground(Vector3Int map_pos, TerrainHier1 hier1){
        // int surface_h = _get_h(map_pos, surface_frequency, surface_max, 0);
        // float frequency_2;
        int surface_h = _GCfg._noise._get_heights(new(map_pos.x, 0), hier1.surface);
        // foreach (NoiseCfg s in hier1.surface){
        //     // frequency_2 = float.Parse(f[1]);
        //     surface_h += _get_h(map_pos, s);
        // }

        if (map_pos.y > surface_h) return false;
        else return true;
    }
    
    // ---------- Vertical Edge ---------- //
    // - "x+" => “type_value +-/==“ => "(if +-)grassland => desert"
    // - "x-" => “type_value +-/==“ => "(if +-)grassland => desert"
    // - 我一直不太懂该怎么翻译比较好，这个是地貌边缘，即某个范围内的x共享一个值，这里草原过去了是沙漠这样子
    public float _get_type_value(Vector3Int map_pos, TerrainHierBase hier_base){
        // _GCfg._noise._fractal_none();
        // _GCfg._noise._noise_perlin();
        // float x_noise = _GCfg._noise._get(map_pos.x, map_pos.y, frequency);
        int x_noise = _GCfg._noise._get_heights(map_pos, hier_base.x_noise);
        float type_value = _GCfg._noise._get_ratio(new (map_pos.x + x_noise, 0, 0), hier_base.Hier1);
        // float x_noise = _GCfg._noise._perlin(map_pos.x, map_pos.y, frequency);
        // _GCfg._noise._noise_cellular_cell();
        // float type_value = _GCfg._noise._get(map_pos.x + x_noise * vertical_edge_noise_scale, frequency);
        // float type_value = _GCfg._noise._cellular_cell(map_pos.x + x_noise * vertical_edge_noise_scale, frequency);
        return type_value;
    }

    public TerrainHier1 _get_hier1(Vector3Int map_pos, TerrainHierBase hier_base){
        float type_value = _get_type_value(map_pos, hier_base);
        int type_ID = RandomGenerator._random_by_prob(_MatSys._terrain._hier1s_prob, type_value);
        TerrainHier1 hier1 = _MatSys._terrain._hier1s[type_ID];
        return hier1;
    }

}