#include <iostream>
#include <vector>
#include <string>
#include <cmath>   
#include <iomanip>
#include <fstream>
#include <bitset>
using namespace std;

#define num_inputs                    49
#define num_hidden_layers             1
#define learning_rate                 0.15
#define num_outputs                   3
#define num_iterations                1000
#define allowable_error               0.1



#define number_of_training_data 15       // each figure
#define PROBABILITY_INCORRECT_PIXEL 0.07 // in database
int max_rand = 10/(PROBABILITY_INCORRECT_PIXEL*10); 
                            
float database[number_of_training_data * 3][7][7]; 
float reference_circle [7][7] = {
   {0, 0, 0, 0, 0, 0, 0}, 
   {0, 0, 1, 1, 1, 0, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {0, 0, 1, 1, 1, 0, 0},
   {0, 0, 0, 0, 0, 0, 0}};

float reference_square [7][7] = {
   {0, 0, 0, 0, 0, 0, 0}, 
   {0, 1, 1, 1, 1, 1, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {0, 1, 1, 1, 1, 1, 0},
   {0, 0, 0, 0, 0, 0, 0}};


float reference_triangle [7][7] = {
   {0, 0, 0, 0, 0, 0, 0}, 
   {0, 0, 0, 1, 0, 0, 0},
   {0, 0, 1, 0, 1, 0, 0},
   {0, 1, 0, 0, 0, 1, 0},
   {1, 0, 0, 0, 0, 0, 1},
   {1, 1, 1, 1, 1, 1, 1},
   {0, 0, 0, 0, 0, 0, 0}};
 


void generation_database (int number_of_training_data_in) {

int database_index = 0;

  while (database_index < number_of_training_data_in*3)
  {
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        // The probability of occurrence of a broken pixel
        // If the following expression is 0, then it is now a broken pixel
        if (rand()%max_rand == 0) {
          if (reference_circle[i][j] == 1) database[database_index][i][j] = 0;
          else                             database[database_index][i][j] = 1;
        }
        else 
          database[database_index][i][j] = reference_circle[i][j];          
      }
    }
    database_index += 1;
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        // The probability of occurrence of a broken pixel
        // If the following expression is 0, then it is now a broken pixel
        if (rand()%max_rand == 0) {       
          if (reference_square[i][j] == 1) database[database_index][i][j] = 0;
          else                             database[database_index][i][j] = 1;
        } 
        else 
          database[database_index][i][j] = reference_square[i][j];
      }
    }
    database_index += 1;
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        // The probability of occurrence of a broken pixel
        // If the following expression is 0, then it is now a broken pixel
        if (rand()%max_rand == 0) {     
          if (reference_triangle[i][j] == 1) database[database_index][i][j] = 0;
          else                               database[database_index][i][j] = 1;    
        }
        else 
          database[database_index][i][j] = reference_triangle[i][j];        
      }
    }
    database_index += 1;
  }

}

void print_data_base(int number_of_training_data_in)
  {
    for (int database_index = 0; database_index < number_of_training_data_in*3; database_index++){
      std:: cout <<  database_index << " figure" << std::endl;
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 7; j++) {
          std:: cout  << database[database_index][i][j] << " ";
        }
        std:: cout  << "\n";
        
      }
      std:: cout  << "\n";
      
    }
  }

float sigmoid(float x) {
    return 1 / (1 + exp(-x));
}

void train_network(float inputs[][num_inputs], float outputs[][3], int num_hidden_neurons_per_layer[], float hidden_weights[], float output_weights[], float error_limit) {
// Инициализация весов

int num_hidden_weights = num_inputs * num_hidden_neurons_per_layer[0];
for (int i = 1; i < num_hidden_layers; i++) {
    num_hidden_weights += num_hidden_neurons_per_layer[i-1] * num_hidden_neurons_per_layer[i];
}
int num_output_weights = num_hidden_neurons_per_layer[num_hidden_layers-1] * 3;
for (int i = 0; i < num_hidden_weights; i++) {
hidden_weights[i] = ((float) rand() / RAND_MAX) * 2 - 1;
}
for (int i = 0; i < num_output_weights; i++) {
output_weights[i] = ((float) rand() / RAND_MAX) * 2 - 1;
}

// Обучение нейронной сети
clock_t start_time = clock();
int iter = 0;
float error = error_limit + 1;
while (error > error_limit) {
    iter ++;
    error = 0;
    for (int i = 0; i < number_of_training_data * 3; i++) {
        // Прямое распространение сигнала
        float hidden_output[num_hidden_layers][num_hidden_neurons_per_layer[num_hidden_layers-1]];
        for (int j = 0; j < num_hidden_layers; j++) {
            int num_inputs_for_layer = j == 0 ? 49 : num_hidden_neurons_per_layer[j-1];
            for (int k = 0; k < num_hidden_neurons_per_layer[j]; k++) {
                float sum = 0;
                for (int l = 0; l < num_inputs_for_layer; l++) {
                    if (j == 0) {
                        sum += inputs[i][l] * hidden_weights[k*49+l];
                    } else {
                        sum += hidden_output[j-1][l] * hidden_weights[(k*num_inputs_for_layer)+l];
                    }
                }
                hidden_output[j][k] = sigmoid(sum);
            }
        }
        float output[3];
        for (int j = 0; j < 3; j++) {
            float sum = 0;
            for (int k = 0; k < num_hidden_neurons_per_layer[num_hidden_layers-1]; k++) {
                sum += hidden_output[num_hidden_layers-1][k] * output_weights[k*3+j];
            }
            output[j] = sigmoid(sum);
        }

        // Обратное распространение ошибки
        float output_error[3];
        for (int j = 0; j < 3; j++) {
            float err = (outputs[i][j] - output[j]) * output[j] * (1 - output[j]);
            error += err * err;
            output_error[j] = err;
            for (int k = 0; k < num_hidden_neurons_per_layer[num_hidden_layers-1]; k++) {
                output_weights[k*3+j] += learning_rate * err * hidden_output[num_hidden_layers-1][k];
            }
        }
        float hidden_error[num_hidden_layers][num_hidden_neurons_per_layer[num_hidden_layers-1]];
        for (int j = num_hidden_layers-1; j >= 0; j--) {
            int num_neurons_for_layer = num_hidden_neurons_per_layer[j];
            for (int k = 0; k < num_neurons_for_layer; k++) {
                float err = 0;
                if (j == num_hidden_layers-1) {
                    for (int l = 0; l < 3; l++) {
                        err += output_error[l] * output_weights[k*3+l];
                    }
                } else {
                    int num_neurons_for_next_layer = num_hidden_neurons_per_layer[j+1];
                    for (int l = 0; l < num_neurons_for_next_layer; l++) {
                        err += hidden_error[j+1][l] * hidden_weights[(l*num_neurons_for_layer)+k];
                    }
                }
                err *= hidden_output[j][k] * (1 - hidden_output[j][k]);
                error += err * err;
                hidden_error[j][k] = err;
                int num_inputs_for_layer = j == 0 ? 49 : num_hidden_neurons_per_layer[j-1];
                for (int l = 0; l < num_inputs_for_layer; l++) {
                    if (j == 0) {
                        hidden_weights[k*49+l] += learning_rate * err * inputs[i][l];
                    } else {
                        hidden_weights[(k*num_inputs_for_layer)+l] += learning_rate * err * hidden_output[j-1][l];
                    }
                }
            }
        }
    }
    
      }
   clock_t end_time = clock();
    float total_time = (float)(end_time - start_time) / CLOCKS_PER_SEC;
    std:: cout << "Обучение завершено. Время обучения: " << total_time << "сек. Колличестсо итераций " << iter << " ошибка " << error << "\n";
    }


int predict_shape(float inputs[num_inputs], int num_hidden_neurons_per_layer[], float hidden_weights[], float output_weights[]) {

   
            float hidden_output[num_hidden_layers][num_hidden_neurons_per_layer[num_hidden_layers-1]];
            for (int j = 0; j < num_hidden_layers; j++) {
                int num_inputs_for_layer = j == 0 ? 49 : num_hidden_neurons_per_layer[j-1];
                for (int k = 0; k < num_hidden_neurons_per_layer[j]; k++) {
                    float sum = 0;
                    for (int l = 0; l < num_inputs_for_layer; l++) {
                        if (j == 0) {
                            sum += inputs[l] * hidden_weights[k*49+l];
                        } else {
                            sum += hidden_output[j-1][l] * hidden_weights[(k*num_inputs_for_layer)+l];
                        }
                    }
                    hidden_output[j][k] = sigmoid(sum);
                }
            }
            float output[3];
            for (int j = 0; j < 3; j++) {
                float sum = 0;
                for (int k = 0; k < num_hidden_neurons_per_layer[num_hidden_layers-1]; k++) {
                    sum += hidden_output[num_hidden_layers-1][k] * output_weights[k*3+j];
                }
                output[j] = sigmoid(sum);
            }            

            int max_index = 0;
            float max_value = output[0];
            for (int i = 1; i < 3; i++) {
              if (output[i] > max_value) {
              max_index = i;
              max_value = output[i];
              }
            }

            return max_index;
            }

int main() {
  int  num_hidden_neurons_per_layer[num_hidden_layers] = {21};

  generation_database(number_of_training_data);
  print_data_base    (number_of_training_data);

  // Определение входных данных и ожидаемых выходных данных
  float inputs   [number_of_training_data * 3][49];
  float outputs  [number_of_training_data * 3][3];

  for (int i = 0; i < number_of_training_data; i++) {

    outputs[i][0] = 1;
    outputs[i][1] = 0;
    outputs[i][2] = 0;
  }
  for (int i = number_of_training_data; i < number_of_training_data * 2; i++) {

    outputs[i][0] = 0;
    outputs[i][1] = 1;
    outputs[i][2] = 0;
  }
  for (int i = number_of_training_data*2; i < number_of_training_data * 3; i++) {
    outputs[i][0] = 0;
    outputs[i][1] = 0;
    outputs[i][2] = 1;
  }

  for (int i = 0; i < number_of_training_data * 3; i++) {
    int input_index = 0;
    for (int j = 0; j < 7; j++) {
      for (int k = 0; k < 7; k++) {
        inputs[i][input_index] = (float)database[i][j][k];
        input_index++;
      }
    }
  }



  // Инициализация весов скрытых и выходных слоев
  int num_hidden_weights = num_inputs * num_hidden_neurons_per_layer[0];
  for (int i = 1; i < num_hidden_layers; i++) {
    num_hidden_weights += num_hidden_neurons_per_layer[i-1] * num_hidden_neurons_per_layer[i];
  }
  float hidden_weights[num_hidden_weights];
  float output_weights[num_hidden_neurons_per_layer[num_hidden_layers-1] * 3];



  train_network(inputs, outputs, num_hidden_neurons_per_layer, hidden_weights, output_weights, allowable_error);

  int predicted_shape;

 // Test the neural network with new input data
  float test_input_triangle[]= {0, 0, 1, 0, 0, 0, 1, 
                                   0, 0, 0, 1, 0, 0, 0, 
                                   0, 0, 1, 0, 1, 0, 0, 
                                   0, 1, 0, 0, 0, 1, 0, 
                                   1, 1, 1, 0, 0, 1, 1, 
                                   1, 1, 1, 1, 1, 1, 1, 
                                   0, 0, 0, 0, 0, 0, 0};
                                  
  std:: cout  << "triangle" << " ";  
  cout  << "\n";  
  for (int j = 0; j < 49; j++) {
      std:: cout  << test_input_triangle[j] << " ";
      if ((j + 1)%7 == 0) cout  << "\n";
    }
    
    predicted_shape = predict_shape(test_input_triangle, num_hidden_neurons_per_layer, hidden_weights, output_weights);
    if ( predicted_shape == 0) {
        cout << "The shape is a circle" << endl;
    } else if (predicted_shape == 1) {
        cout << "The shape is a square" << endl;
     }else if (predicted_shape == 2) {
        cout << "The shape is a triangle" << endl;
      }

    cout  << "\n";
    cout  << "\n";

 // Test the neural network with new input data
    float test_input_square[]= { 0, 1, 0, 0, 0, 0, 1, 
                                  0, 1, 1, 1, 1, 1, 0, 
                                  0, 1, 0, 0, 1, 1, 1, 
                                  0, 1, 0, 0, 0, 1, 0, 
                                  0, 1, 0, 0, 1, 1, 0, 
                                  0, 1, 1, 1, 1, 1, 0, 
                                  0, 0, 0, 0, 0, 0, 0};
    std:: cout  << "square" << " ";               
    cout  << "\n";
    for (int j = 0; j < 49; j++) {
      std:: cout  << test_input_square[j] << " ";
      if ((j + 1)%7 == 0) cout  << "\n";
    }
    predicted_shape = predict_shape(test_input_square, num_hidden_neurons_per_layer, hidden_weights, output_weights);
    if (predicted_shape == 0) {
        cout << "The shape is a triangle" << endl;
    } else if (predicted_shape == 1) {
        cout << "The shape is a square" << endl;
     }else if (predicted_shape == 2) {
        cout << "The shape is a triangle" << endl;
      }
    cout  << "\n";
    cout  << "\n";

 // Test the neural network with new input data
    float test_input_circle[]= { 0, 0, 0, 0, 0, 0, 0, 
                                  0, 0, 1, 1, 1, 0, 0, 
                                  0, 0, 0, 0, 0, 1, 0, 
                                  1, 1, 0, 0, 0, 1, 0, 
                                  0, 1, 0, 1, 0, 1, 0, 
                                  0, 0, 0, 1, 1, 0, 0, 
                                  0, 0, 0, 0, 0, 0, 0};
    std:: cout  << "circle" << " ";    
    cout  << "\n";           
    for (int j = 0; j < 49; j++) {
      std:: cout  << test_input_circle[j] << " ";
      if ((j + 1)%7 == 0) cout  << "\n";
    }
    predicted_shape = predict_shape(test_input_circle, num_hidden_neurons_per_layer, hidden_weights, output_weights);
    if (predicted_shape == 0) {
        cout << "The shape is a circle" << endl;
    } else if (predicted_shape == 1) {
        cout << "The shape is a square" << endl;
     }else if (predicted_shape == 2) {
        cout << "The shape is a triangle" << endl;
      }

for (int i = 0; i < num_hidden_weights; i++) {
    std::cout << hidden_weights[i] << " ";
}
std::cout << std::endl;  // перевод строки в конце вывода
int num_output_weights = num_hidden_neurons_per_layer[num_hidden_layers-1] * 3;
  // Удаление файла, если он уже существует
  const char* filename = "weights.txt";
  if (std::remove(filename) != 0) {
    std::cerr << "Error: failed to remove file" << std::endl;
  }

  // Открытие текстового файла для записи
  std::ofstream outfile(filename);
  if (!outfile.is_open()) {
    std::cerr << "Error: failed to open file" << std::endl;
    return 1;
  }

  // Запись массива hidden_weights в шестнадцатеричном формате
  outfile << std::hex << std::uppercase << std::setfill('0');
  for (int i = 0; i < num_hidden_weights; i++) {
    outfile << std::setw(8) << *(reinterpret_cast<unsigned int*>(&hidden_weights[i])) << "\n";
  }
  outfile << std::endl;

  // Запись массива output_weights в шестнадцатеричном формате
  for (int i = 0; i < num_output_weights; i++) {
    outfile << std::setw(8) << *(reinterpret_cast<unsigned int*>(&output_weights[i])) << "\n";
  }
  outfile << std::endl;

  // Закрытие файла
  outfile.close();
  return 0;

}
