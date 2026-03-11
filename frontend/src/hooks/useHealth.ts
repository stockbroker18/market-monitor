import { useQuery } from "@tanstack/react-query";
import axios from "axios";

export interface HealthResponse {
  status: string;
  bloomberg_connected: boolean;
  message: string;
}

export function useHealth(backendUrl: string) {
  return useQuery<HealthResponse>({
    queryKey: ["health", backendUrl],
    queryFn: async () => {
      const res = await axios.get(`${backendUrl}/health`);
      return res.data;
    },
    refetchInterval: 10000,
    retry: false,
  });
}
