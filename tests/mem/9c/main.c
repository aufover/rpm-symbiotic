#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a;
  if (1 > 0)
  {
    a = malloc(sizeof(int));
  }
  *a = 42;
  free(a);
}
