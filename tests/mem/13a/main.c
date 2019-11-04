#include<stdlib.h>
int main (int argc, char** argv)
{
  int **a;
  int b = 5;
  a = malloc(b*sizeof(int *));
  for (int i = 0; i < b ; i++)
  {
    a[i] = malloc(b *sizeof(int));
  }
  for (int i = 0; i < b; i++)
    for (int j = 0; j < b; j++)
    {
      a[i][j] = i*j;
    }
  for (int i = 0; i < b ; i++)
  {
      free(a[i]);
  }
  free(a);
  return 0;
}
