# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "clustername" {
  description = "Name of cluster"
  type        = string
  default     = "kroon-cluster"

}

variable "accountid" {
  description = "Harness accountid"
  type        = string

}


variable "apikey" {
  description = "Harness APIkey"
  type        = string

}
