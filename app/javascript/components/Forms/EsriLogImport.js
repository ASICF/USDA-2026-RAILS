import React, { useState, useEffect, useRef } from "react";
import {
  Button,
  Grid,
  Header,
  Label,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
  Icon,
  List,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function EsriLogImport({ required_folder, token }) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  console.log("UpTimeLogImport", { token });

  const resetForm = () => {
    reset({
      file: "",
    });
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setLoading(true)
    setSubmitted(true)
    axios
      .post(`/esri_log_import`, {
        authenticity_token: token,
        input_directory: data.input_directory,
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setSubmitted(false)
        setLoading(false)
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        // Reset form if successful
        if (data.state) {
          setTimeout(() => {
            resetForm();
          }, 500);
        }
        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
      });
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Inputs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>ESRI Logs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Import</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {/* {renderHelp()} */}
      {/* <Divider /> */}
      {renderMessage()}
      {renderForm()}
    </div>
  );

  //   function renderHelp() {
  //     return (
  //       <Accordion styled fluid>
  //         <Accordion.Title
  //           active={accordionState}
  //           onClick={() => {
  //             setAccordionState(!accordionState);
  //           }}
  //         >
  //           <Icon name="dropdown" />
  //           Tool Help
  //         </Accordion.Title>
  //         <Accordion.Content active={accordionState}>
  //           <Header as="h4">Summary</Header>
  //           <p>Imports the DOQQs via Shapefile</p>
  //           <Divider />
  //           <Grid divided="vertically">
  //             <Grid.Row columns={2}>
  //               <Grid.Column>
  //                 <Header as="h5">Inputs</Header>
  //                 <List bulleted>
  //                   <List.Item>
  //                     A <b>single shapefile</b> that contains a{" "}
  //                     <b>.shp, .shx, .dbf, and .prj</b> files
  //                   </List.Item>
  //                 </List>
  //               </Grid.Column>
  //               <Grid.Column>
  //                 <Header as="h5">Process</Header>
  //                 <List bulleted>
  //                   <List.Item>
  //                     The associationed County, State, and UTM will be verified
  //                     and calculated
  //                   </List.Item>
  //                 </List>
  //               </Grid.Column>
  //             </Grid.Row>
  //           </Grid>
  //         </Accordion.Content>
  //       </Accordion>
  //     );
  //   }

  function renderMessage() {
    if (!message) return null;

    return (
      <MessageBox
        status={message.status}
        title={message.title}
        message={message.text}
      />
    );
  }

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"input_directory"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label={`Directory to Log Files (Must be a nested folder of ${required_folder})`}
                autoComplete="off"
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                error={
                  errors["input_directory"] && errors["input_directory"].message
                }
              />
            )}
          />
        </Form.Group>

        <Divider />

        <Button
          primary
          floated="right"
          type="button"
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onSubmit)}
        >
          Submit
        </Button>
        <Button
          secondary
          floated="right"
          type="button"
          onClick={() => resetForm()}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }
}
