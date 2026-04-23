# img_to_csv.py — Processing sketch: image → CSV values
# Source gist: https://gist.github.com/palletorsson/3c46686bf8a20d1132392a3a766a8f15
# Doc section: Processing sketch
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import java.io.FileWriter;
import java.io.IOException;
import processing.core.PImage;

PImage img;
String csvFilename = "/Users/pato/Documents/Processing/csvpixel/data/pixels.csv";
int stepSize = 5; // How many pixels to skip each time
float brightnessThreshold = 127; // The brightness threshold below which a pixel is considered "dark"

void setup() {
  size(640, 480);
  img = loadImage("ghost.png"); // Load your image
  img.resize(width, height); // Resize to match the sketch size for simplicity
  background(255);
  image(img, 0, 0);
  savePixelsToCSV();
}

void savePixelsToCSV() {
  // Prepare the writer
  FileWriter csvWriter = null;
  try {
    csvWriter = new FileWriter(csvFilename);
    println(csvFilename);

    // Iterate over each row
    for (int y = 0; y < img.height; y += stepSize) {
      StringBuilder row = new StringBuilder();
      
      // Iterate over each column in the row
      for (int x = 0; x < img.width; x += stepSize) {
        int pixelColor = img.get(x, y);
        float pixelBrightness = brightness(pixelColor);
        
        // Check if the pixel is dark
        int isDark = pixelBrightness < brightnessThreshold ? 1 : 0;
        
        // Append to the current row's string
        row.append(isDark);
        if (x < img.width - stepSize) {
          row.append(","); // No comma at the end of the row
        }
      }
      
      // Write the row to the CSV and start a new line
      csvWriter.append(row.toString() + "\n");
    }
  } catch (IOException e) {
    e.printStackTrace();
  } finally {
    try {
      if (csvWriter != null) csvWriter.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
   }
