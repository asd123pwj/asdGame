// Thanks to Auburn, I copy FastNoiseLite in 2024/09/13, https://github.com/Auburn/FastNoiseLite/blob/master/CSharp/FastNoiseLite.cs


public class Noise{
    public int seed;
    // FastNoise _noise_generator;
    FastNoiseLite _noise_generator;

    public Noise(int seed=-1){
        if (seed == -1) seed = System.DateTime.Now.Millisecond;
        this.seed = seed;
        _noise_generator = new(seed);
    }

    public float _perlin(float x, float y, float scale){
        _noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Perlin);
        _noise_generator.SetFrequency(0.01f*scale);
        float noise_value = _noise_generator.GetNoise(x, y);
        return noise_value;
    }

    public float _perlin(float x, float scale){
        float noise_value = _perlin(x, 0, scale);
        return noise_value;
    }

    static float _perlin(float x, float y, float scale, int seed){
        FastNoiseLite noise_generator = new(seed);
        noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Perlin);
        noise_generator.SetFrequency(0.01f*scale);
        float noise_value = noise_generator.GetNoise(x, y);
        return noise_value;
    }

    static float _perlin(float x, float scale, int seed){
        float noise_value = _perlin(x, 0, scale, seed);
        return noise_value;
    }
}

