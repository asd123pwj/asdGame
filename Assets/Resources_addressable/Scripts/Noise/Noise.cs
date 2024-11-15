// Thanks to Auburn, I copy FastNoiseLite in 2024/09/13, https://github.com/Auburn/FastNoiseLite/blob/master/CSharp/FastNoiseLite.cs


using System.Collections.Generic;
using UnityEngine;

public class Noise{
    public int seed;
    // FastNoise _noise_generator;
    FastNoiseLite _noise_generator;

    public Noise(int seed=-1){
        if (seed == -1) seed = System.DateTime.Now.Millisecond;
        this.seed = seed;
        _noise_generator = new(seed);
    }

    public float _get(float x, float y, float frequnency, bool norm=true){
        _noise_generator.SetFrequency(0.01f*frequnency);
        float noise_value = _noise_generator.GetNoise(x, y);
        if (norm) noise_value = (noise_value + 1) / 2;
        return noise_value;
    }
    public float _get(float x, float frequnency, bool norm=true) => _get(x, 0, frequnency, norm);

    public float _get_ratio(Vector3Int pos, NoiseCfg cfg){
        _set_fractal_type(cfg.fractal);
        _set_noise(cfg.noise);
        float ratio = _get(pos.x, pos.y, cfg.f);
        // float h = (cfg.max - cfg.min) * h_ratio + cfg.min;
        return ratio;
    }
    public int _get_height(Vector3Int pos, NoiseCfg cfg) => Mathf.FloorToInt((cfg.max - cfg.min) * _get_ratio(pos, cfg) + cfg.min);

    public int _get_heights(Vector3Int pos, List<NoiseCfg> cfgs){
        int h = 0;
        foreach(NoiseCfg cfg in cfgs){
            h += _get_height(pos, cfg);
        }
        return h;
    }

    public bool _get_2D(Vector3Int map_pos, NoiseCfg cfg){
        _set_fractal_type(cfg.fractal);
        _set_noise(cfg.noise);
        float h_ratio = _get(map_pos.x, map_pos.y, cfg.f);
        bool allowGenerate = true;
        if (cfg.min != 0 && h_ratio < cfg.min) allowGenerate = false;
        if (cfg.max != 0 && h_ratio > cfg.max) allowGenerate = false;
        return allowGenerate;
    }

    public bool _get_2Ds(Vector3Int map_pos, List<NoiseCfg> cfgs){
        foreach(NoiseCfg cfg in cfgs){
            if (!_get_2D(map_pos, cfg)) return false;
        }
        return true;
    }

    // ---------- Noise Type ----------
    // ----- 1. Perlin Noise -----
    public void _set_noise(FastNoiseLite.NoiseType noise_type) => _noise_generator.SetNoiseType(noise_type);
    public void _noise_perlin() => _set_noise(FastNoiseLite.NoiseType.Perlin);
    public void _noise_cellular_cell() { _set_noise(FastNoiseLite.NoiseType.Cellular); _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.CellValue);}
    public void _noise_cellular_2div() { _set_noise(FastNoiseLite.NoiseType.Cellular); _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.Distance2Div);}
    public void _set_noise(string noise_type){
        switch(noise_type){
            case "perlin": _noise_perlin(); break;
            case "cellular_cell": _noise_cellular_cell(); break;
            case "cellular_2div": _noise_cellular_2div(); break;
            default: _noise_perlin(); break;
        }
    }


    // public float _perlin(float x, float y, float frequnency){
    //     _noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Perlin);
    //     return _get(x, y, frequnency);
    // }
    // public float _perlin(float x, float frequnency) => _perlin(x, 0, frequnency);
    // public float _perlin_01(float x, float y, float frequnency) => (_perlin(x, y, frequnency) + 1) / 2;
    // public float _perlin_01(float x, float frequnency) => _perlin_01(x, 0, frequnency);

    // // ----- 2. Cellular Noise -----
    // public float _cellular_cell(float x, float y, float frequnency) {
    //     _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.CellValue);
    //     _noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Cellular);
    //     return _get(x, y, frequnency);
    // }
    // public float _cellular_cell(float x, float frequnency) => _cellular_cell(x, 0, frequnency);


    // public float _cellular_2div(float x, float y, float frequnency) {
    //     _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.Distance2Div);
    //     _noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Cellular);
    //     return _get(x, y, frequnency);
    // }
    // public float _cellular_2div(float x, float frequnency) => _cellular_2div(x, 0, frequnency);
    // public float _cellular_2div_01(float x, float y, float frequnency) => (_cellular_2div(x, y, frequnency) + 1) / 2;
    // public float _cellular_2div_01(float x, float frequnency) => _cellular_2div_01(x, 0, frequnency);

    // ---------- Fractal Type ----------
    public void _set_fractal_type(FastNoiseLite.FractalType fractal_type) => _noise_generator.SetFractalType(fractal_type);
    public void _fractal_none() => _set_fractal_type(FastNoiseLite.FractalType.None);
    public void _fractal_fbm() => _set_fractal_type(FastNoiseLite.FractalType.FBm);
    public void _fractal_ridged() => _set_fractal_type(FastNoiseLite.FractalType.Ridged);
    public void _fractal_pingpong() => _set_fractal_type(FastNoiseLite.FractalType.PingPong);
    public void _set_fractal_type(string fractal_type) {
        switch (fractal_type) {
            case "fbm":      _fractal_fbm(); break;
            case "ridged":   _fractal_ridged(); break;
            case "pingpong": _fractal_pingpong(); break;
            default:         _fractal_none(); break;
        }
    }
}

