#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a = malloc(sizeof(int));
  if (1 > 0)
  {
    free(a);
  }
  *a = 42;
  free(a);
  return 0;
}
