module "standard_cluster" {
  source = "./modules/standard_cluster"

  project_name = var.project_name
  region       = var.region
  zone         = var.zone
}
