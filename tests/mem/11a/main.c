#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a[10];
  for (int i=0; i<10;i++)
  {
    a[i] = malloc(sizeof(int));
  }
  for (int i=0; i<10;i++)
  {
    *a[i] = i;
  }
  for (int i=0; i<10;i++)
  {
    free(a[i]);
  }
  return 0;
}
