package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	log "github.com/sirupsen/logrus"
	"net"
	"net/http"
	"os"
)

type Droplet struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Networks struct {
		V4 []struct {
			IP string `json:"ip_address"`
		} `json:"v4"`
	} `json:"networks"`
}

type Droplets struct {
	Droplets []Droplet `json:"droplets"`
}

var (
	token    string
	debug    = flag.Bool("debug", false, "enable debug")
	domain   = flag.String("domain", "pijupiju.com", "domain")
	record   = flag.String("record", "116193794", "record id")
	instance = flag.String("instance", "csgo", "droplet name")
)

func getDroplets() (d Droplets) {
	log.Debugf("getDroplets()")

	client := &http.Client{}
	req, err := http.NewRequest("GET", "https://api.digitalocean.com/v2/droplets", nil)
	if err != nil {
		log.Fatalf("http.NewRequest [%v]", err)
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

	res, err := client.Do(req)
	if err != nil {
		log.Fatalf("client.Do [%v]", err)
	}
	log.Debugf("  res.Status [%v]", res.Status)

	err = json.NewDecoder(res.Body).Decode(&d)
	if err != nil {
		log.Fatalf("json.NewDecoder [%v]", err)
	}

	log.Debugf("  res.Body [%v]", d)
	return
}

func getTargetIP(droplets Droplets, target string) (ip string) {
	log.Debugf("getTargetIP()")

	for _, droplet := range droplets.Droplets {
		if droplet.Name == target {
			ip = droplet.Networks.V4[1].IP
		}
	}

	log.Debugf("  ip [%v]", ip)
	return
}

func updateDNS(domain, record, ip string) {
	log.Debugf("updateDNS()")

	url := fmt.Sprintf("https://api.digitalocean.com/v2/domains/%v/records/%v", domain, record)
	log.Debugf("  url [%v]", url)
	payload, err := json.Marshal(struct{ Data string `json:"data"` }{ip})
	if err != nil {
		log.Fatalf("json.Marshal [%v]", err)
	}
	log.Debugf("  payload [%v]", string(payload))

	client := &http.Client{}
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(payload))
	if err != nil {
		log.Fatalf("http.NewRequest [%v]", err)
	}
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Set("Content-Type", "application/json")

	res, err := client.Do(req)
	if err != nil {
		log.Fatalf("client.Do [%v]", err)
	}

	log.Debugf("  res.Status [%v]", res.Status)
}

func resolveIPs(domain string) {
	ips, err := net.LookupIP(domain)
	if err != nil {
		log.Fatalf("net.LookupIP [%v]", err)
	}

	for _, ip := range ips {
		log.Infof("%v [%v]", domain, ip)
	}
}

func init() {
	flag.Parse()
	if *debug {
		log.SetLevel(log.DebugLevel)
	}

	token = os.Getenv("DO_PAT")
	if token == "" {
		log.Fatalf("token not exported (DO_PAT) [!]")
	}
}

func main() {
	log.Infof("mapdns start")

	droplets := getDroplets()
	ip := getTargetIP(droplets, *instance)
	log.Infof("%v droplet ip [%v]", *instance, ip)

	updateDNS(*domain, *record, ip)
	resolveIPs(fmt.Sprintf("%v.%v", *instance, *domain))

	log.Infof("all done \\o/")
}
