using UnityEngine;

public class TilemapVisualization: BaseClass{
    GameObject self;
    LineRenderer lineRenderer;
    
    public override void _init(){
        self = new GameObject("LineRenderer");
        self.transform.SetParent(_sys._system.transform);
        self.transform.position = new(-0.5f, -0.5f, 0);
        lineRenderer = self.AddComponent<LineRenderer>();
        int rows = 900, cols = 1600;
        float cellSize = 1f;
        lineRenderer.material = new Material(Shader.Find("Sprites/Default"));
        lineRenderer.startWidth = 0.1f;
        lineRenderer.endWidth = 0.1f;
        lineRenderer.startColor = Color.white;
        lineRenderer.endColor = Color.white;
        lineRenderer.sortingLayerName = "UI-Foreground";

        float start_x = cols / 2 * cellSize;
        float start_y = rows / 2 * cellSize;

        int index = 0;
        for (int i = 0; i < rows; i += 2) index += 4;
        for (int i = 0; i < cols; i += 2) index += 4;
        lineRenderer.positionCount = index;

        index = 0;
        for (int i = 0; i < rows; i += 2){
            lineRenderer.SetPosition(index++, new Vector3(-start_x, -start_y + i * cellSize, 0));
            lineRenderer.SetPosition(index++, new Vector3(start_x, -start_y + i * cellSize, 0));
            lineRenderer.SetPosition(index++, new Vector3(start_x, -start_y + (i + 1) * cellSize, 0));
            lineRenderer.SetPosition(index++, new Vector3(-start_x, -start_y + (i + 1) * cellSize, 0));
        }
        
        for (int i = 0; i < cols; i += 2){
            lineRenderer.SetPosition(index++, new Vector3(-start_x + i * cellSize, -start_y, 0));
            lineRenderer.SetPosition(index++, new Vector3(-start_x + i * cellSize, start_y, 0));
            lineRenderer.SetPosition(index++, new Vector3(-start_x + (i + 1) * cellSize, start_y, 0));
            lineRenderer.SetPosition(index++, new Vector3(-start_x + (i + 1) * cellSize, -start_y, 0));
        }

    }
}
