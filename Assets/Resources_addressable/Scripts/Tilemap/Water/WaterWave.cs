using UnityEngine;


public class WaterWave : BaseClass{
    public float waveSpeed = 1f;
    public float waveHeight = 20f;
    public float waveFrequency = 1f;
    public int wave_row_start = 2;

    // ----- P3D
    float P3D_scale = 1.5f; // 1.5f is for P3D, 1 is front, 0.5 is up/side
    float hh = .125f; // 1 / 6 * 1.5f / 2, hh means haft of h1
    float h1 = .25f; // 1 / 6 * 1.5f
    float h2 = .5f; // 2 / 6 * 1.5f
    float wh = .125f; // 1 / 6 * 1.5f / 2, wh means haft of w1
    float w1 = .25f; // 1 / 6 * 1.5f
    float w2 = .5f; // 2 / 6 * 1.5f

    public static Vector3[] vertices_6x6_front          = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSide      = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH0d5  = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH1d0  = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH1d5  = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH2d0  = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH2d5  = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH3d0  = new Vector3[49];
    public static Vector3[] vertices_6x6_frontSideH3d5  = new Vector3[49];



    public WaterWave(){
        for (int x = 0; x < 7; x++){
            for (int y = 0; y < 7; y++){
                int x_ = Mathf.Min(x, 5 - 1); // remove P3D point
                int y_ = Mathf.Min(y, 5 - 1); // remove P3D point
                vertices_6x6_front[ixy.i(x_, y_, 7)] = new() { x = (float)x_ / (7 - 1) * P3D_scale, y = (float)y_ / (7 - 1) * P3D_scale }; 
            }
        }
        vertices_6x6_frontSide = (Vector3[])vertices_6x6_front.Clone();
        int col = 7;
        // ----- Up ----- //
        vertices_6x6_frontSide[ixy.i(0, 5, col)] = vertices_6x6_frontSide[ixy.i(0, 4, col)];
        vertices_6x6_frontSide[ixy.i(0, 6, col)] = vertices_6x6_frontSide[ixy.i(0, 4, col)];
        vertices_6x6_frontSide[ixy.i(1, 5, col)] = vertices_6x6_frontSide[ixy.i(1, 4, col)];
        vertices_6x6_frontSide[ixy.i(1, 6, col)] = vertices_6x6_frontSide[ixy.i(1, 4, col)];
        vertices_6x6_frontSide[ixy.i(2, 5, col)] = vertices_6x6_frontSide[ixy.i(2, 4, col)];
        vertices_6x6_frontSide[ixy.i(2, 6, col)] = vertices_6x6_frontSide[ixy.i(2, 4, col)];
        vertices_6x6_frontSide[ixy.i(3, 5, col)] = vertices_6x6_frontSide[ixy.i(3, 4, col)];
        vertices_6x6_frontSide[ixy.i(3, 6, col)] = vertices_6x6_frontSide[ixy.i(3, 4, col)];
        vertices_6x6_frontSide[ixy.i(4, 5, col)] = vertices_6x6_frontSide[ixy.i(4, 4, col)];
        vertices_6x6_frontSide[ixy.i(4, 6, col)] = vertices_6x6_frontSide[ixy.i(4, 4, col)];
        vertices_6x6_frontSide[ixy.i(5, 5, col)] = vertices_6x6_frontSide[ixy.i(4, 4, col)] + new Vector3(w1, h1, 0);
        vertices_6x6_frontSide[ixy.i(5, 6, col)] = vertices_6x6_frontSide[ixy.i(5, 5, col)];
        vertices_6x6_frontSide[ixy.i(6, 6, col)] = vertices_6x6_frontSide[ixy.i(4, 4, col)] + new Vector3(w2, h2, 0);
        
        // ----- Side ----- //
        vertices_6x6_frontSide[ixy.i(5, 0, col)] = vertices_6x6_frontSide[ixy.i(4, 0, col)];
        vertices_6x6_frontSide[ixy.i(6, 0, col)] = vertices_6x6_frontSide[ixy.i(4, 0, col)];
        vertices_6x6_frontSide[ixy.i(5, 1, col)] = vertices_6x6_frontSide[ixy.i(4, 0, col)] + new Vector3(w1, h1, 0);
        vertices_6x6_frontSide[ixy.i(6, 1, col)] = vertices_6x6_frontSide[ixy.i(5, 1, col)];
        vertices_6x6_frontSide[ixy.i(5, 2, col)] = vertices_6x6_frontSide[ixy.i(4, 1, col)] + new Vector3(w1, h1, 0);
        vertices_6x6_frontSide[ixy.i(6, 2, col)] = vertices_6x6_frontSide[ixy.i(4, 0, col)] + new Vector3(w2, h2, 0);
        vertices_6x6_frontSide[ixy.i(5, 3, col)] = vertices_6x6_frontSide[ixy.i(4, 2, col)] + new Vector3(w1, h1, 0);
        vertices_6x6_frontSide[ixy.i(6, 3, col)] = vertices_6x6_frontSide[ixy.i(4, 1, col)] + new Vector3(w2, h2, 0);
        vertices_6x6_frontSide[ixy.i(5, 4, col)] = vertices_6x6_frontSide[ixy.i(4, 3, col)] + new Vector3(w1, h1, 0);
        vertices_6x6_frontSide[ixy.i(6, 4, col)] = vertices_6x6_frontSide[ixy.i(4, 2, col)] + new Vector3(w2, h2, 0);
        vertices_6x6_frontSide[ixy.i(6, 5, col)] = vertices_6x6_frontSide[ixy.i(4, 3, col)] + new Vector3(w2, h2, 0);

        vertices_6x6_frontSideH0d5 = (Vector3[])vertices_6x6_frontSide.Clone();
        vertices_6x6_frontSideH0d5[ixy.i(4, 0, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH0d5[ixy.i(5, 1, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH0d5[ixy.i(6, 2, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH0d5[ixy.i(5, 0, col)] = vertices_6x6_frontSideH0d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH0d5[ixy.i(6, 0, col)] = vertices_6x6_frontSideH0d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH0d5[ixy.i(5, 1, col)] = vertices_6x6_frontSideH0d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH0d5[ixy.i(6, 1, col)] = vertices_6x6_frontSideH0d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH0d5[ixy.i(6, 2, col)] = vertices_6x6_frontSideH0d5[ixy.i(5, 2, col)];

        vertices_6x6_frontSideH1d0 = (Vector3[])vertices_6x6_frontSide.Clone();  
        vertices_6x6_frontSideH1d0[ixy.i(5, 0, col)] = vertices_6x6_frontSideH1d0[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH1d0[ixy.i(6, 0, col)] = vertices_6x6_frontSideH1d0[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH1d0[ixy.i(5, 1, col)] = vertices_6x6_frontSideH1d0[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH1d0[ixy.i(6, 1, col)] = vertices_6x6_frontSideH1d0[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH1d0[ixy.i(6, 2, col)] = vertices_6x6_frontSideH1d0[ixy.i(5, 2, col)];

        vertices_6x6_frontSideH1d5 = (Vector3[])vertices_6x6_frontSide.Clone();  
        vertices_6x6_frontSideH1d5[ixy.i(4, 1, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH1d5[ixy.i(5, 2, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH1d5[ixy.i(6, 3, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH1d5[ixy.i(5, 0, col)] = vertices_6x6_frontSideH1d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH1d5[ixy.i(6, 0, col)] = vertices_6x6_frontSideH1d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH1d5[ixy.i(5, 1, col)] = vertices_6x6_frontSideH1d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH1d5[ixy.i(6, 1, col)] = vertices_6x6_frontSideH1d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH1d5[ixy.i(6, 2, col)] = vertices_6x6_frontSideH1d5[ixy.i(5, 2, col)];


        vertices_6x6_frontSideH2d0 = (Vector3[])vertices_6x6_frontSide.Clone();
        vertices_6x6_frontSideH2d0[ixy.i(5, 0, col)] = vertices_6x6_frontSideH2d0[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH2d0[ixy.i(6, 0, col)] = vertices_6x6_frontSideH2d0[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH2d0[ixy.i(5, 1, col)] = vertices_6x6_frontSideH2d0[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH2d0[ixy.i(6, 1, col)] = vertices_6x6_frontSideH2d0[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH2d0[ixy.i(5, 2, col)] = vertices_6x6_frontSideH2d0[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH2d0[ixy.i(6, 2, col)] = vertices_6x6_frontSideH2d0[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH2d0[ixy.i(6, 3, col)] = vertices_6x6_frontSideH2d0[ixy.i(5, 3, col)];

        vertices_6x6_frontSideH2d5 = (Vector3[])vertices_6x6_frontSide.Clone();
        vertices_6x6_frontSideH2d5[ixy.i(4, 2, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH2d5[ixy.i(5, 3, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH2d5[ixy.i(6, 4, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH2d5[ixy.i(5, 0, col)] = vertices_6x6_frontSideH2d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH2d5[ixy.i(6, 0, col)] = vertices_6x6_frontSideH2d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH2d5[ixy.i(5, 1, col)] = vertices_6x6_frontSideH2d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH2d5[ixy.i(6, 1, col)] = vertices_6x6_frontSideH2d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH2d5[ixy.i(5, 2, col)] = vertices_6x6_frontSideH2d5[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH2d5[ixy.i(6, 2, col)] = vertices_6x6_frontSideH2d5[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH2d5[ixy.i(6, 3, col)] = vertices_6x6_frontSideH2d5[ixy.i(5, 3, col)];

        vertices_6x6_frontSideH3d0 = (Vector3[])vertices_6x6_frontSide.Clone();
        vertices_6x6_frontSideH3d0[ixy.i(5, 0, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH3d0[ixy.i(6, 0, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH3d0[ixy.i(5, 1, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH3d0[ixy.i(6, 1, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH3d0[ixy.i(5, 2, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH3d0[ixy.i(6, 2, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH3d0[ixy.i(5, 3, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 3, col)];
        vertices_6x6_frontSideH3d0[ixy.i(6, 3, col)] = vertices_6x6_frontSideH3d0[ixy.i(4, 3, col)];
        vertices_6x6_frontSideH3d0[ixy.i(6, 4, col)] = vertices_6x6_frontSideH3d0[ixy.i(5, 4, col)];

        vertices_6x6_frontSideH3d5 = (Vector3[])vertices_6x6_frontSide.Clone();
        vertices_6x6_frontSideH3d5[ixy.i(4, 3, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH3d5[ixy.i(5, 4, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH3d5[ixy.i(6, 5, col)] += new Vector3(0, hh, 0);
        vertices_6x6_frontSideH3d5[ixy.i(5, 0, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH3d5[ixy.i(6, 0, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 0, col)];
        vertices_6x6_frontSideH3d5[ixy.i(5, 1, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH3d5[ixy.i(6, 1, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 1, col)];
        vertices_6x6_frontSideH3d5[ixy.i(5, 2, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH3d5[ixy.i(6, 2, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 2, col)];
        vertices_6x6_frontSideH3d5[ixy.i(5, 3, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 3, col)];
        vertices_6x6_frontSideH3d5[ixy.i(6, 3, col)] = vertices_6x6_frontSideH3d5[ixy.i(4, 3, col)];
        vertices_6x6_frontSideH3d5[ixy.i(6, 4, col)] = vertices_6x6_frontSideH3d5[ixy.i(5, 4, col)];


    }
    
    public void _wave(WaterBase water){
        if (water._amount == 0) {
            water._self.SetActive(false);
            return;
        }
        water._self.SetActive(true);
        if (water._isToppest){
            _scale_to_amount(water);
            water._textureStatus = WaterTextureStatus.Dynamic;
            return;
        }
        if (water._right == null || water._right._amount == 0){
            if (water._textureStatus == WaterTextureStatus.FrontSide) return;
            water.mesh.vertices = vertices_6x6_frontSide;
            water._textureStatus = WaterTextureStatus.FrontSide;
            water.mesh.RecalculateNormals();
        }
        else if (water._right._textureStatus == WaterTextureStatus.FrontSide || water._right._textureStatus == WaterTextureStatus.Front){
            if (water._textureStatus == WaterTextureStatus.Front) return;
            water.mesh.vertices = vertices_6x6_front;
            water._textureStatus = WaterTextureStatus.Front;
            water.mesh.RecalculateNormals();
        }
        else{
            float side_height = (water._amount + water._right._amount) / 2f;
            water._textureStatus = WaterTextureStatus.FrontSideDynamic;
            if (side_height == 0.5f)
                water.mesh.vertices = vertices_6x6_frontSideH0d5;
            else if (side_height == 1f)
                water.mesh.vertices = vertices_6x6_frontSideH1d0;
            else if (side_height == 1.5f)
                water.mesh.vertices = vertices_6x6_frontSideH1d5;
            else if (side_height == 2f)
                water.mesh.vertices = vertices_6x6_frontSideH2d0;
            else if (side_height == 2.5f)
                water.mesh.vertices = vertices_6x6_frontSideH2d5;
            else if (side_height == 3f)
                water.mesh.vertices = vertices_6x6_frontSideH3d0;
            else if (side_height == 3.5f)
                water.mesh.vertices = vertices_6x6_frontSideH3d5;
            else if (side_height == 4f){
                water.mesh.vertices = vertices_6x6_front;
                water._textureStatus = WaterTextureStatus.Front;
            }
            else
                Debug.Log("Happen water should not happen");
            water.mesh.RecalculateNormals();
                
        }
    }
    
    public void _scale_to_amount(WaterBase water){
        Vector3[] vertices_new = new Vector3[water.mesh.vertices.Length];

        int row_front = 5, col_front = 5; // Front
        int row = 7, col = 7;             // Full, i.e., Front + Up + Side

        // ----- Water continuous ----- //
        int amount_left, amount_right;
        if (TilemapTile._check_fullTile(water._layer, water._map_pos + Vector3Int.left))
            amount_left = water._amount;
        else
            amount_left = (water._left != null) ? water._left._amount : 0;

        if (TilemapTile._check_fullTile(water._layer, water._map_pos + Vector3Int.right))
            amount_right = water._amount;
        else
            amount_right = (water._right != null) ? water._right._amount : 0;

        float height = (float)water._amount / GameConfigs._sysCfg.water_full_amount;
        float height_left = (float)amount_left / GameConfigs._sysCfg.water_full_amount;
        float height_right = (float)amount_right / GameConfigs._sysCfg.water_full_amount;

        // ----- Water wave ----- //
        float[] heights = new float[5]{
            height + (height_left  - height) / 2,
            height + (height_left  - height) / 8,
            height,
            height + (height_right - height) / 8,
            height + (height_right - height) / 2
        };
        // ----- Front ----- //
        float x_, y_;
        for (int x = 0; x < col_front; x++){
            for (int y = 0; y < row_front; y++){
                int i = ixy.i(x, y, col);
                Vector3 vertex = water.mesh.vertices[i];
                x_ = (float)x / (col - 3); // col - 1 is normalization, col - 1 - 2 is P3D normalization
                y_ = (float)y / (row - 3);
                y_ = Mathf.Min(y_, heights[x]);
                vertex.x = x_ ; 
                vertex.y = y_ ;
                vertices_new[i] = vertex;
            }
        }

        // ---------- Water P3D ---------- //
        // ----- Up ----- //
        vertices_new[ixy.i(0, 5, col)] = vertices_new[ixy.i(0, 4, col)];
        vertices_new[ixy.i(0, 6, col)] = vertices_new[ixy.i(0, 4, col)];
        vertices_new[ixy.i(1, 5, col)] = vertices_new[ixy.i(0, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(1, 6, col)] = vertices_new[ixy.i(1, 5, col)];
        vertices_new[ixy.i(2, 5, col)] = vertices_new[ixy.i(1, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(2, 6, col)] = vertices_new[ixy.i(0, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(3, 5, col)] = vertices_new[ixy.i(2, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(3, 6, col)] = vertices_new[ixy.i(1, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(4, 5, col)] = vertices_new[ixy.i(3, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(4, 6, col)] = vertices_new[ixy.i(2, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(5, 5, col)] = vertices_new[ixy.i(4, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(5, 6, col)] = vertices_new[ixy.i(3, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(6, 6, col)] = vertices_new[ixy.i(4, 4, col)] + new Vector3(w2, h2, 0);

        // ----- Side ----- //
        bool have_water_right = water._right != null && water._right._amount > 0;
        float W1 = have_water_right ? 0 : w1;
        float W2 = have_water_right ? 0 : w2;
        vertices_new[ixy.i(5, 0, col)] = vertices_new[ixy.i(4, 0, col)];
        vertices_new[ixy.i(6, 0, col)] = vertices_new[ixy.i(4, 0, col)];
        vertices_new[ixy.i(5, 1, col)] = vertices_new[ixy.i(4, 0, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 1, col)] = vertices_new[ixy.i(5, 1, col)];
        vertices_new[ixy.i(5, 2, col)] = vertices_new[ixy.i(4, 1, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 2, col)] = vertices_new[ixy.i(4, 0, col)] + new Vector3(W2, h2, 0);
        vertices_new[ixy.i(5, 3, col)] = vertices_new[ixy.i(4, 2, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 3, col)] = vertices_new[ixy.i(4, 2, col)] + new Vector3(W2, h2, 0);
        vertices_new[ixy.i(5, 4, col)] = vertices_new[ixy.i(4, 3, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 4, col)] = vertices_new[ixy.i(4, 3, col)] + new Vector3(W2, h2, 0);
        vertices_new[ixy.i(6, 5, col)] = vertices_new[ixy.i(4, 4, col)] + new Vector3(W2, h2, 0);

        water.mesh.vertices = vertices_new;
        water.mesh.RecalculateNormals();
    }
}