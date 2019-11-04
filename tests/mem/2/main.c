int main (int argc, char** argv)
{
  int *a;
  a = malloc(sizeof(int));
  *a = 10;
  free(a);
  free(a);
}
