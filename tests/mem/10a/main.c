#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a = malloc(sizeof(int));
  int b = 0;
  if (b > 0)
  {
    free(a);
  }
  *a = 42;
  free(a);
  return 0;
}
