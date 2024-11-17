// Thanks to Auburn, I copy FastNoiseLite in 2024/09/13, https://github.com/Auburn/FastNoiseLite/blob/master/CSharp/FastNoiseLite.cs


using System.Collections.Generic;
using UnityEngine;

public class Noise{
    public int seed;
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

    // ---------- Get Noise ----------
    public float _get_ratio(Vector3Int pos, NoiseCfg cfg){
        _set_fractal_type(cfg.fractal);
        _set_noise(cfg.noise);
        float ratio = _get(pos.x, pos.y, cfg.f);
        ratio = (cfg.max - cfg.min) * ratio + cfg.min;
        return ratio;
    }
    public int _get_height(Vector3Int pos, NoiseCfg cfg) => Mathf.FloorToInt(_get_ratio(pos, cfg));

    // public int _get_heights(Vector3Int pos, List<NoiseCfg> cfgs){
    //     int h = 0;
    //     foreach(NoiseCfg cfg in cfgs){
    //         h += _get_height(pos, cfg);
    //     }
    //     return h;
    // }

    public bool _get_2D(Vector3Int map_pos, NoiseCfg cfg){
        _set_fractal_type(cfg.fractal);
        _set_noise(cfg.noise);
        float h_ratio = _get(map_pos.x, map_pos.y, cfg.f);
        bool allowGenerate = true;
        if (cfg.min != 0 && h_ratio < cfg.min) allowGenerate = false;
        if (cfg.max != 0 && h_ratio > cfg.max) allowGenerate = false;
        return allowGenerate;
    }

    // public bool _get_2Ds(Vector3Int map_pos, List<NoiseCfg> cfgs){
    //     foreach(NoiseCfg cfg in cfgs){
    //         if (!_get_2D(map_pos, cfg)) return false;
    //     }
    //     return true;
    // }

    public bool _get_bool(Vector3Int pos, List<NoiseCfg> cfgs){
        bool allow = cfgs == null;
        Vector3Int pos_with_noise = new();
        if (cfgs != null) foreach(NoiseCfg cfg in cfgs){
            pos_with_noise.x = _get_int(pos, cfg.x_noise) + (cfg.ignoreX ? 0 : pos.x);
            pos_with_noise.y = _get_int(pos, cfg.y_noise) + (cfg.ignoreY ? 0 : pos.y);
            if (cfg.precondition != null && !_get_bool(pos_with_noise, cfg.precondition)) continue;
            if (_get_2D(pos_with_noise, cfg)) allow = true;
        }
        return allow;
    }

    public int _get_int(Vector3Int pos, List<NoiseCfg> cfgs){
        int value = 0;
        Vector3Int pos_with_noise = new();
        if (cfgs != null) foreach(NoiseCfg cfg in cfgs){
            pos_with_noise.x = _get_int(pos, cfg.x_noise) + (cfg.ignoreX ? 0 : pos.x);
            pos_with_noise.y = _get_int(pos, cfg.y_noise) + (cfg.ignoreY ? 0 : pos.y);
            if (cfg.precondition != null && !_get_bool(pos_with_noise, cfg.precondition)) continue;
            value += _get_height(pos_with_noise, cfg);
        }
        return value;
    }
    
    public float _get_float(Vector3Int pos, List<NoiseCfg> cfgs){
        float value = 0;
        Vector3Int pos_with_noise = new();
        if (cfgs != null) foreach(NoiseCfg cfg in cfgs){
            pos_with_noise.x = _get_int(pos, cfg.x_noise) + (cfg.ignoreX ? 0 : pos.x);
            pos_with_noise.y = _get_int(pos, cfg.y_noise) + (cfg.ignoreY ? 0 : pos.y);
            if (cfg.precondition != null && !_get_bool(pos_with_noise, cfg.precondition)) continue;
            value += _get_ratio(pos_with_noise, cfg);
        }
        return value;
    }

    // ---------- Noise Type ----------
    public void _set_noise(FastNoiseLite.NoiseType noise_type) => _noise_generator.SetNoiseType(noise_type);
    public void _noise_perlin() => _set_noise(FastNoiseLite.NoiseType.Perlin);
    public void _noise_cellular() { _set_noise(FastNoiseLite.NoiseType.Cellular); _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.Distance);}
    public void _noise_cellular_cell() { _set_noise(FastNoiseLite.NoiseType.Cellular); _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.CellValue);}
    public void _noise_cellular_2div() { _set_noise(FastNoiseLite.NoiseType.Cellular); _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.Distance2Div);}
    public void _noise_simplex2() => _set_noise(FastNoiseLite.NoiseType.OpenSimplex2);
    public void _noise_simplex2s() => _set_noise(FastNoiseLite.NoiseType.OpenSimplex2S);
    public void _set_noise(string noise_type){
        switch(noise_type){
            case "perlin": _noise_perlin(); break;
            case "cellular": _noise_cellular(); break;
            case "cellular_cell": _noise_cellular_cell(); break;
            case "cellular_2div": _noise_cellular_2div(); break;
            case "simplex2": _noise_simplex2(); break;
            case "simplex2s": _noise_simplex2s(); break;
            default: _noise_perlin(); break;
        }
    }

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

