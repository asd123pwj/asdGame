// Thanks to Auburn, I copy FastNoiseLite in 2024/09/13, https://github.com/Auburn/FastNoiseLite/blob/master/CSharp/FastNoiseLite.cs


public class Noise{
    public int seed;
    // FastNoise _noise_generator;
    FastNoiseLite _noise_generator;

    public Noise(int seed=-1){
        if (seed == -1) seed = System.DateTime.Now.Millisecond;
        this.seed = seed;
        _noise_generator = new(seed);
        _noise_generator.SetCellularReturnType(FastNoiseLite.CellularReturnType.CellValue);
    }

    public float _perlin(float x, float y, float frequnency){
        _noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Perlin);
        _noise_generator.SetFrequency(0.01f*frequnency);
        float noise_value = _noise_generator.GetNoise(x, y);
        return noise_value;
    }
    public float _perlin(float x, float frequnency) => _perlin(x, 0, frequnency);
    public float _perlin_01(float x, float y, float frequnency) => (_perlin(x, y, frequnency) + 1) / 2;
    public float _perlin_01(float x, float frequnency) => _perlin_01(x, 0, frequnency);

    public float _cellular(float x, float y, float frequnency) {
        _noise_generator.SetNoiseType(FastNoiseLite.NoiseType.Cellular);
        _noise_generator.SetFrequency(0.01f*frequnency);
        float noise_value = _noise_generator.GetNoise(x, y);
        return noise_value;
    }
    public float _cellular(float x, float frequnency) => _cellular(x, 0, frequnency);


}

