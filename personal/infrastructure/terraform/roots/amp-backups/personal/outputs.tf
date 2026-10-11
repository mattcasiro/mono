output "backup_buckets" {
  value = [for _, bucket in module.bucket : bucket.name]
}