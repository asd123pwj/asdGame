// Thanks to Auburn and other authers of FastNoise, I copied it in 2023/9/2 from https://github.com/Auburn/FastNoise_CSharp

public class Noise{
    public int seed;
    FastNoise _noise_generator;

    public Noise(int seed=-1){
        if (seed == -1) seed = System.DateTime.Now.Millisecond;
        this.seed = seed;
        _noise_generator = new(seed);
    }

    public float _perlin(float x, float y, float scale){
        _noise_generator.SetNoiseType(FastNoise.NoiseType.Perlin);
        _noise_generator.SetFrequency(0.01f*scale);
        float noise_value = _noise_generator.GetNoise(x, y);
        return noise_value;
    }

    public float _perlin(float x, float scale){
        float noise_value = _perlin(x, 0, scale);
        return noise_value;
    }

    static float _perlin(float x, float y, float scale, int seed){
        FastNoise noise_generator = new(seed);
        noise_generator.SetNoiseType(FastNoise.NoiseType.Perlin);
        noise_generator.SetFrequency(0.01f*scale);
        float noise_value = noise_generator.GetNoise(x, y);
        return noise_value;
    }

    static float _perlin(float x, float scale, int seed){
        float noise_value = _perlin(x, 0, scale, seed);
        return noise_value;
    }
}

